#!/usr/bin/env bash

. ./export-env-vars.sh

docker image rm "$CONTAINER_REGISTRY_PATH"/"$WORKER_IMAGE_C" 2> /dev/null
docker pull "$CONTAINER_REGISTRY_PATH"/ide-worker-c

docker image rm "$CONTAINER_REGISTRY_PATH"/"$WORKER_IMAGE_CPP" 2> /dev/null
docker pull "$CONTAINER_REGISTRY_PATH"/"$WORKER_IMAGE_CPP"

docker image rm "$CONTAINER_REGISTRY_PATH"/"$WORKER_IMAGE_PYTHON2" 2> /dev/null
docker pull "$CONTAINER_REGISTRY_PATH"/"$WORKER_IMAGE_PYTHON2"

docker image rm "$CONTAINER_REGISTRY_PATH"/"$WORKER_IMAGE_PYTHON3" 2> /dev/null
docker pull "$CONTAINER_REGISTRY_PATH"/"$WORKER_IMAGE_PYTHON3"

docker image rm "$CONTAINER_REGISTRY_PATH"/"$WORKER_IMAGE_NODEJS8" 2> /dev/null
docker pull "$CONTAINER_REGISTRY_PATH"/"$WORKER_IMAGE_NODEJS8"

docker image rm "$CONTAINER_REGISTRY_PATH"/"$WORKER_IMAGE_JAVA8" 2> /dev/null
docker pull "$CONTAINER_REGISTRY_PATH"/"$WORKER_IMAGE_JAVA8"
