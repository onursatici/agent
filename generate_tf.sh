#!/usr/bin/env bash

# transform all k8s yaml files in given folder into tf resources
# requires https://github.com/sl1pm4t/k2tf
set -euxo pipefail
YAMLS="${1:-"operations/helm/tests/create-deployment/grafana-agent/templates"}"

rm grafana-agent.tf 2> /dev/null || true
find "${YAMLS}" -name "*yaml" | xargs -L 1 -I{} sh -c "k2tf -f {} >> grafana-agent.tf"
