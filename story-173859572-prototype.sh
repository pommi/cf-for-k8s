#!/bin/bash

set -eux

DOMAIN=$K8S_ENV
FULL_DOMAIN=${DOMAIN}.k8s-dev.relint.rocks
secrets_file=/tmp/${DOMAIN}-secrets.yml
service_key_file=# <<location of a downloaded GCP service account key>>

./hack/generate-secrets.sh -d $FULL_DOMAIN -s > $secrets_file

if [[ ! -f foundation-values.yml ]] ; then
  # In the near term operators/platform engineers will have to construct this file manually.
  # This prototype uses a hack script to create it if needed
  ./hack/generate-foundation-values.sh -d $FULL_DOMAIN -g $service_key_file -s > foundation-values.yml
fi

# Use yajsv to validate foundation-values.yml against the schema
which yajsv || go get github.com/neilpa/yajsv
yajsv -s schema.json foundation-values.yml

kapp deploy -a cf -f <(ytt -f ./config -f foundation-values.yml -f "$secrets_file") -y
