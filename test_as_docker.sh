#!/usr/bin/env bash

# shellcheck disable=SC2086

. ./export-env-vars.sh

docker run \
--rm \
--mount 'type=bind,src=/tmp/box,dst=/tmp/box' \
--mount 'type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock' \
--user root \
--env CONTAINER_REGISTRY_PATH=$CONTAINER_REGISTRY_PATH \
"$TASKMASTER_CONTAINER_NAME" \
sh -c "printenv && npm install -D && exec npm run test"
