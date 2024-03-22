#!/bin/bash

cd /opt/FuzionView

# Generate UUMPT Mapfile (from DB config)
# Make sure postgresql is ready before starting
while(true) ; do
	(cd mapserver && ./gen_uumpt_map.py > uumpt.map) && break
	sleep 3
done

apache2ctl -DFOREGROUND
