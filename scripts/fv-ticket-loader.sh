#!/bin/bash

cd /opt/FuzionView

# Make sure fv-api-server are ready before starting
while(true) ; do
    echo "Checking if fv-api-server is ready..."
    curl --silent --fail -H "Accept: application/json" "http://fv-api-server:8080/owners" && break
    sleep 3
done

while(true) ; do
	# Generate new tickets
	./ticket_loaders/fake/fake_ticket_generator --generate --send --tickets-api http://fv-api-server:8080/tickets

	sleep 3600 
done
