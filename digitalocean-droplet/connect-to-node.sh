#!/usr/bin/env bash

DROPLET_NAME=gitpod-k3s
IP=$(doctl compute droplet get "$DROPLET_NAME" --format PublicIPv4 --no-header)
ssh "root@$IP"
