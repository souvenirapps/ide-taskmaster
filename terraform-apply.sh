#!/usr/bin/env bash

cd "$(dirname "$0")" || exit

PWD=$(pwd)

. ./export-env-vars.sh

if [ -z "$GCS_BUCKET_NAME" ]; then
  printf "Environment variable \$GCS_BUCKET_NAME is not set.\n"
  exit 1
fi

if [ -z "$GCS_BUCKET_PATH" ]; then
  printf "Environment variable \$GCS_BUCKET_PATH is not set.\n"
  exit 1
fi

cd ./terraform || (printf "Cannot find terraform directory.\n" && exit 1)

terraform init \
  --backend-config "bucket=$GCS_BUCKET_NAME" \
  --backend-config "prefix=$GCS_BUCKET_PATH"

terraform fmt -check

terraform validate

terraform taint google_compute_instance_template.ide_worker 2> /dev/null

terraform plan -refresh=true -out=tfplan

terraform apply -auto-approve -lock=true tfplan
