FROM docker.io/library/debian:12 as deb-base

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get clean && apt-get autoclean && apt-get autoremove


################################ Mapserver ##########################
FROM deb-base as build-mapserver

# MapServer Build Deps
# Should probably just build this as a .deb so deps are handled properly

RUN find /etc/apt/sources.list* -type f -exec sed -i 's/Types: deb/Types: deb deb-src /' '{}' + && \
    apt-get update && \
    apt-get build-dep -y mapserver

# MapServer build-dep pulls in libcurl4-gnutls-dev which breaks libcurlpp which expects the openssl version
RUN apt-get install -y \
    libcurl4-openssl-dev    

WORKDIR /src
COPY src/mapserver mapserver
RUN mkdir build && cd build && \
    cmake ../mapserver \
        -DCMAKE_INSTALL_PREFIX="/opt/mapserver/8.2" \
        -DCMAKE_INSTALL_SYSCONFDIR="/opt/mapserver/8.2"/etc \
        -DWITH_KML=1 \
        -DWITH_SOS=1 \
        -DWITH_WMS=1 \
        -DWITH_FRIBIDI=0 \
        -DWITH_ICONV=1 \
        -DWITH_CAIRO=1 \
        -DWITH_SVGCAIRO=0 \
        -DWITH_RSVG=1 \
        -DWITH_MYSQL=0 \
        -DWITH_FCGI=1 \
        -DWITH_GEOS=1 \
        -DWITH_POSTGIS=1 \
        -DWITH_CURL=1 \
        -DWITH_CLIENT_WMS=1 \
        -DWITH_CLIENT_WFS=1 \
        -DWITH_WFS=1 \
        -DWITH_WCS=1 \
        -DWITH_LIBXML2=1 \
        -DWITH_THREAD_SAFETY=1 \
        -DWITH_GIF=1 \
        -DWITH_PYTHON=0 \
        -DWITH_PERL=0 \
        -DWITH_RUBY=0 \
        -DWITH_JAVA=0 \
        -DWITH_CSHARP=0 \
        -DWITH_ORACLE_PLUGIN=0 \
        -DWITH_MSSQL2008=0 \
        -DWITH_EXEMPI=0 \
        -DWITH_XMLMAPFILE=0 \
        -DWITH_HARFBUZZ=0 && \
    make && \
    make install && \
    mkdir /opt/mapserver/8.2/cgi-bin && \
    ln /opt/mapserver/8.2/bin/mapserv /opt/mapserver/8.2/cgi-bin && \
    cp /opt/mapserver/8.2/etc/mapserver-sample.conf /opt/mapserver/8.2/etc/mapserver.conf


############################## FV Documentation #########################
FROM deb-base as build-fv-docs

RUN apt-get install -y \
    python3-sphinx \
    python3-sphinx-rtd-theme \
    make

WORKDIR /src
COPY src/FV-Docs .

RUN make html

################################ FV API Server ##########################
FROM deb-base as build-fv-engine

# FV-Engine Build Deps
RUN apt-get install -y \
    make \
    g++ \
    git \
    libasio-dev \
    libboost-all-dev \
    libgdal-dev \
    libpqxx-dev \
    libcurlpp-dev

WORKDIR /src
COPY src/FV-Engine FV-Engine

RUN cd FV-Engine && \
    make -j$(nproc) && \
    make install prefix=/opt/FuzionView



################################ FV Node Client ##########################
FROM docker.io/library/node:21-alpine as build-fv-client

WORKDIR /src
COPY src/FV-Client .

RUN npm install && npm run build:docker


############################### FV Admin Rails ###########################
FROM deb-base as build-fv-admin

RUN apt-get install -y \
        build-essential \
	ruby-dev \
	ruby-bundler \
	libpq-dev \
	libyaml-dev

WORKDIR /opt/FuzionView/admin
COPY src/FV-Admin .
RUN chmod 1777 /opt/FuzionView/admin/tmp

RUN bundle install --deployment

# Rails config
COPY opt/FuzionView/admin/env /opt/FuzionView/admin/.env
RUN bundle exec rails assets:precompile


############################### Demo Image ###############################
FROM deb-base

LABEL org.opencontainers.image.source=https://github.com/FuzionView/FV-Demo
LABEL org.opencontainers.image.description="Self contained FuzionView Demo image"
#LABEL org.opencontainers.image.licenses=GPL-3.0-only

RUN apt-get install -y \
      libasan8 \
      libubsan1 \
      libcurlpp0 \
       libgdal32 \
       libpqxx-6.4 \
      libcairo2 \
       libfcgi-bin \
       libgdal32 \
       libglib2.0-0 \
       libprotobuf-c1 \
       librsvg2-2 \
      apache2 \
       libapache2-mod-passenger \
       python3-psycopg2 \
       postgresql-client \
       curl \
      postgresql-postgis

COPY --from=build-mapserver /opt/mapserver /opt/mapserver
COPY --from=build-fv-engine /opt/FuzionView /opt/FuzionView
COPY --from=build-fv-client /src/dist /opt/FuzionView/static_html/dist
COPY --from=build-fv-admin /opt/FuzionView/admin /opt/FuzionView/admin
COPY static_html /opt/FuzionView/static_html
COPY --from=build-fv-docs /src/build/html /opt/FuzionView/static_html/docs

COPY scripts /opt/FuzionView/scripts

# Install Apache Config
COPY etc /etc
RUN a2enmod actions cgid headers http2 passenger proxy proxy_http rewrite ssl socache_shmcb && \
    a2ensite default-ssl && \
    rm -r /var/www/html && ln -s /opt/FuzionView/static_html /var/www/html

# pgpass pg_service.conf
COPY --chmod=600 pg-user/pgpass /root/.pgpass
COPY --chmod=600 --chown=www-data pg-user/pgpass /var/www/.pgpass

COPY pg-user/pg_service.conf /root/.pg_service.conf
COPY pg-user/pg_service.conf /var/www/.pg_service.conf
COPY opt/FuzionView/gpg /opt/FuzionView/gpg

CMD ["/opt/FuzionView/scripts/run.sh"]
