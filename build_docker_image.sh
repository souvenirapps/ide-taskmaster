#!/usr/bin/env bash

cd "$(dirname "$0")" || exit

. ./export-env-vars.sh

docker network create --internal --subnet 10.1.1.0/24 no-internet

docker image rm "$TASKMASTER_CONTAINER_NAME" 2> /dev/null

docker build -t "$TASKMASTER_CONTAINER_NAME" .
