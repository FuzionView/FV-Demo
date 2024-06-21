#!/bin/bash

cd /opt/FuzionView

# Generate UUMPT Mapfile (from DB config)
# Make sure postgresql is ready before starting
while(true) ; do
	(cd mapserver && ./generate_mapfiles) && break
	sleep 3
done

apache2ctl -DFOREGROUND
