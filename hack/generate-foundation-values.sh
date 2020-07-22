#!/usr/bin/env bash

# This is a hack! see https://github.com/cloudfoundry/cf-for-k8s/blob/develop/hack/README.md
set -euo pipefail

function usage_text() {
  cat <<EOF
Usage:
  $(basename "$0")

flags:
  -d, --cf-domain
      (required) Root DNS domain name for the CF install
      (e.g. if CF API at api.inglewood.k8s-dev.relint.rocks, cf-domain = inglewood.k8s-dev.relint.rocks)

  -g, --gcr-service-account-json
      (optional) Filepath to the GCP Service Account JSON describing a service account
      that has permissions to write to the project's container repository.

  -s, --silence-hack-warning
      (optional) Omit hack script warning message.

EOF
  exit 1
}

if [[ $# -lt 1 ]]; then
  usage_text >&2
fi

while [[ $# -gt 0 ]]; do
  i=$1
  case $i in
  -d=* | --cf-domain=*)
    DOMAIN="${i#*=}"
    shift
    ;;
  -d | --cf-domain)
    DOMAIN="${2}"
    shift
    shift
    ;;
  -g=* | --gcr-service-account-json=*)
    GCP_SERVICE_ACCOUNT_JSON_FILE="${i#*=}"
    shift
    ;;
  -g | --gcr-service-account-json)
    GCP_SERVICE_ACCOUNT_JSON_FILE="${2}"
    shift
    shift
    ;;
  -s | --silence-hack-warning)
    SILENCE_HACK_WARNING="true"
    shift
    ;;
  *)
    echo -e "Error: Unknown flag: ${i/=*/}\n" >&2
    usage_text >&2
    exit 1
    ;;
  esac
done

if [[ -z ${SILENCE_HACK_WARNING:=} ]]; then
  echo "WARNING: The hack scripts are intended for development of cf-for-k8s.
  They are not officially supported product bits.  Their interface and behavior
  may change at any time without notice." 1>&2
fi

if [[ -z ${DOMAIN:=} ]]; then
  echo "Missing required flag: -d / --cf-domain" >&2
  exit 1
fi

if [[ -n ${GCP_SERVICE_ACCOUNT_JSON_FILE:=} ]]; then
  if [[ ! -r ${GCP_SERVICE_ACCOUNT_JSON_FILE} ]]; then
    echo "Error: Unable to read GCP service account JSON from file: ${GCP_SERVICE_ACCOUNT_JSON_FILE}" >&2
    exit 1
  fi
fi

cat <<EOF
#@data/values
---
system_domain: "${DOMAIN}"
app_domains:
#@overlay/append
- "apps.${DOMAIN}"
EOF

if [[ -n "${GCP_SERVICE_ACCOUNT_JSON_FILE:=}" ]]; then
  cat <<EOF

app_registry:
  hostname: gcr.io
  repository_prefix: gcr.io/$( bosh interpolate ${GCP_SERVICE_ACCOUNT_JSON_FILE} --path=/project_id )/cf-workloads
  username: _json_key
  password: |
$(cat ${GCP_SERVICE_ACCOUNT_JSON_FILE} | sed -e 's/^/    /')
EOF

fi

if [[ -n "${K8S_ENV:-}" ]] ; then
    k8s_env_path=$HOME/workspace/relint-ci-pools/k8s-dev/ready/claimed/"$K8S_ENV"
    if [[ -f "$k8s_env_path" ]] ; then
	      ip_addr=$(jq -r .lb_static_ip < "$k8s_env_path")
        echo 1>&2 "Detected \$K8S_ENV environment var; writing \"istio_static_ip: $ip_addr\" entry to end of output"
        echo "
istio_static_ip: $ip_addr
"
    fi
fi
