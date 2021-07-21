#!/usr/bin/env bash

set -exuo pipefail

doctl account get

DROPLET_NAME=gitpod-k3s
DOMAIN_NAME=ludmann.name
GITPOD_SUBDOMAIN=gitpod.x
LEGO_VOLUME_ID=a705e73d-7d8f-11eb-84cd-0a58ac14d02e

# if given, the helm chart of this commit is used
# leave empty to use latest from charts.gitpod.io
# https://github.com/gitpod-io/gitpod/releases/tag/v0.10.0
GITPOD_COMMIT_ID=f496a745a08e9b8a2be23d8c0b5a326af09b69bc

#DROPLET_SIZE=s-1vcpu-1gb
DROPLET_SIZE=s-2vcpu-4gb

doctl compute droplet create "$DROPLET_NAME" \
    --image ubuntu-20-04-x64 \
    --region fra1 \
    --size "$DROPLET_SIZE" \
    --ssh-keys "$DIGITALOCEAN_SSH_KEY_FINGERPRINT" \
    --volumes "$LEGO_VOLUME_ID" \
    --wait

IP=$(doctl compute droplet get "$DROPLET_NAME" --format PublicIPv4 --no-header)
doctl compute domain records create "$DOMAIN_NAME" --record-type A --record-name "$GITPOD_SUBDOMAIN" --record-data "$IP" --record-ttl 30
doctl compute domain records create "$DOMAIN_NAME" --record-type A --record-name "*.$GITPOD_SUBDOMAIN" --record-data "$IP" --record-ttl 30
doctl compute domain records create "$DOMAIN_NAME" --record-type A --record-name "*.ws.$GITPOD_SUBDOMAIN" --record-data "$IP" --record-ttl 30

doctl compute droplet create "${DROPLET_NAME}-wsnode" \
    --image ubuntu-20-04-x64 \
    --region fra1 \
    --size "$DROPLET_SIZE" \
    --ssh-keys "$DIGITALOCEAN_SSH_KEY_FINGERPRINT" \
    --wait
IP_WSNODE=$(doctl compute droplet get "${DROPLET_NAME}-wsnode" --format PublicIPv4 --no-header)

sleep 30

scp -r gitpod-install "root@$IP:"
ssh "root@$IP" ./gitpod-install/install.sh \
    "$GITPOD_SUBDOMAIN.$DOMAIN_NAME" \
    "letsencrypt@cornelius-ludmann.de" \
    "$DIGITALOCEAN_ACCESS_TOKEN" \
    "$GITPOD_GITHUB_CLIENT_SECRET" \
    "$GITPOD_COMMIT_ID"

mkdir -p ~/.kube
scp "root@$IP:/etc/rancher/k3s/k3s.yaml" ~/.kube/config
sed -i "s+127.0.0.1+$IP+g" ~/.kube/config

scp -r gitpod-install "root@$IP_WSNODE:"
ssh "root@$IP_WSNODE" ./gitpod-install/install-wsnode.sh "https://${IP}:6443"


echo "done"

watch kubectl get pods -o wide
