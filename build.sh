#!/bin/bash

mkdir -p src
(
    cd src
    git clone --depth 1 --recurse-submodules --shallow-submodules git@github.com:FuzionView/FV-Engine
    git clone --depth 1 https://github.com/klassenjs/mapserver -b branch-8-0-klassenjs
    git clone --depth 1 git@github.com:FuzionView/FV-Client
)

DOCKER_BUILDKIT=1 docker-compose build 

echo Start container with: docker-compose up -d 
echo Stop container with: docker-compose down

