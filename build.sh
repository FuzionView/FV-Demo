#!/bin/bash

set -euo pipefail

mkdir -p src
(
    cd src
    [ -d FV-Engine ] || git clone --depth 1 --recurse-submodules --shallow-submodules git@github.com:FuzionView/FV-Engine
    [ -d mapserver ] || git clone --depth 1 https://github.com/klassenjs/mapserver -b branch-8-0-klassenjs
    [ -d FV-Client ] || git clone --depth 1 git@github.com:FuzionView/FV-Client
    [ -d FV-Admin ] || git clone --depth 1 git@github.com:FuzionView/FV-Admin
    [ -d FV-Docs ] || git clone --depth 1 git@github.com:FuzionView/FV-Docs
)

DOCKER=docker
if hash podman-compose ; then
	podman-compose build
	DOCKER=podman
else
	DOCKER_BUILDKIT=1 docker-compose build
fi

echo Start container with: ${DOCKER}-compose up -d
echo Stop container with: ${DOCKER}-compose down

