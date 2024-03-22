#!/bin/bash

set -euo pipefail

cd /opt/FuzionView

if [ ! -f .db_init_done ] ; then
	pg_ctlcluster --skip-systemctl-redirect 15 main start
	# Create DB Users
	su postgres -c "psql --file=./scripts/create_users_database.sql"

	# Load Initial DB Schema
	su postgres -c "psql dbname=fv --file=./schema.sql"

	# Load Fake FO configuration
	su postgres -c "psql dbname=fv --file=./mapserver/fake_fo/load_fv_fake_fo.sql"
	su postgres -c "psql dbname=fv" <<-EOF
	update fv.datasets set source_dataset=replace(source_dataset, 'localhost', 'fv-apache-server');
	\q
	EOF

	# Enable non-local connections
	cat > /etc/postgresql/15/main/conf.d/local.conf <<-EOF
	listen_addresses = '*'
	EOF

	cat >> /etc/postgresql/15/main/pg_hba.conf <<-EOF
	host all all 0.0.0.0/0 scram-sha-256
	EOF

	pg_ctlcluster --skip-systemctl-redirect 15 main stop
	touch .db_init_done
fi

pg_ctlcluster --skip-systemctl-redirect --foreground 15 main start 

