#!/usr/bin/env bash

set -exuo pipefail

DROPLET_NAME=gitpod-k3s
DOMAIN_NAME=ludmann.name

doctl compute droplet delete "$DROPLET_NAME" --force || true
doctl compute droplet delete "${DROPLET_NAME}-wsnode" --force || true
doctl compute droplet list

doctl compute domain records list "$DOMAIN_NAME" --format ID,Name --no-header | grep gitpod | cut -d' ' -f1 | while read -r id; do
    doctl compute domain records delete "$DOMAIN_NAME" "$id" --force
done
doctl compute domain records list "$DOMAIN_NAME"

echo "done"
