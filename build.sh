#!/bin/bash

set -euo pipefail

DOCKER=docker
if hash podman-compose ; then
	podman-compose build
	DOCKER=podman
else
	DOCKER_BUILDKIT=1 docker-compose build
fi

echo Start container with: "${DOCKER}-compose up -d && ${DOCKER}-compose logs -f"
echo Stop container with: "${DOCKER}-compose down -t0"

