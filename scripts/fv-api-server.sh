#!/bin/bash

cd /opt/FuzionView
./fv_api_server/fv_api_server \
	--bind-address 0.0.0.0 \
	--template-dir=./fv_api_server/templates \
	--wms-url="http://fv-apache-server/maps/tickets.map"
