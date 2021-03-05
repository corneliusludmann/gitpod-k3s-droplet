#!/usr/bin/env bash

set -exuo pipefail

export K3S_URL=$1
export K3S_CLUSTER_SECRET=qWo6sn3VWERh3dBBQniPLTqtZzEHURsriJNhTqus
export K3S_NODE_NAME=wsnode
export INSTALL_K3S_EXEC="agent --node-label gitpod.io/workload_workspace=true"

curl -sSfL https://get.k3s.io | sh -
