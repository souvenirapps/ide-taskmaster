#!/usr/bin/env bash

export TASKMASTER_CONTAINER_NAME=ide-taskmaster

export WORKER_IMAGE_C=ide-worker-c
export WORKER_IMAGE_CPP=ide-worker-cpp
export WORKER_IMAGE_NODEJS8=ide-worker-nodejs8
export WORKER_IMAGE_PYTHON2=ide-worker-python2
export WORKER_IMAGE_PYTHON3=ide-worker-python3
export WORKER_IMAGE_JAVA8=ide-worker-java8

TF_VAR_docker_pull_workers=$(cat << EOF
docker pull $CONTAINER_REGISTRY_PATH/$WORKER_IMAGE_C
docker pull $CONTAINER_REGISTRY_PATH/$WORKER_IMAGE_CPP
docker pull $CONTAINER_REGISTRY_PATH/$WORKER_IMAGE_NODEJS8
docker pull $CONTAINER_REGISTRY_PATH/$WORKER_IMAGE_PYTHON2
docker pull $CONTAINER_REGISTRY_PATH/$WORKER_IMAGE_PYTHON3
docker pull $CONTAINER_REGISTRY_PATH/$WORKER_IMAGE_JAVA8
EOF
)

export TF_VAR_docker_pull_workers
