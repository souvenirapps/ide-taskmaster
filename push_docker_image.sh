#!/usr/bin/env bash

cd "$(dirname "$0")" || exit

. ./export-env-vars.sh

gcloud auth configure-docker

docker tag "$TASKMASTER_CONTAINER_NAME" "$CONTAINER_REGISTRY_PATH/$TASKMASTER_CONTAINER_NAME"

docker push "$CONTAINER_REGISTRY_PATH/$TASKMASTER_CONTAINER_NAME"
