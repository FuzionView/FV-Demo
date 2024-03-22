#!/bin/bash

cd /opt/FuzionView

# Make sure postgresql, and fv-apache-server (for fake_fo) are ready before starting
while(true) ; do
    psql "service=sg_fv_cache" -c "select postgis_version()" && \
    curl --silent --fail "http://fv-apache-server/maps/fake_fo/fake_fo.map?SERVICE=WFS&VERSION=2.0.0&REQUEST=GetCapabilities" && \
    break
    sleep 3
done

# Give the ticket generator time for to load the first tickets
sleep 15

while(true) ; do
	# Archive stale tickets (past purge date)
	./db_maint/archive_stale_tickets

	# Fetch features for new tickets
	./db_maint/update_feature_cache

	sleep 300 
done
