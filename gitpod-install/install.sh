#!/usr/bin/env bash

set -exuo pipefail

DOMAIN=$1
LETS_ENCRYPT_EMAIL=$2
DO_AUTH_TOKEN=$3
export DO_AUTH_TOKEN
GITPOD_GITHUB_CLIENT_SECRET=$4
GITPOD_COMMIT_ID=${5:-}
GITPOD_CHART_VERSION=


# Install lego Let's encrypt
curl -sSOL https://github.com/go-acme/lego/releases/download/v4.2.0/lego_v4.2.0_linux_amd64.tar.gz
tar -xf lego_v4.2.0_linux_amd64.tar.gz
mv lego /usr/local/bin/
rm CHANGELOG.md LICENSE lego_v4.2.0_linux_amd64.tar.gz

mkdir -p /mnt/gitpod_k3s_lego
mount -o discard,defaults,noatime /dev/disk/by-id/scsi-0DO_Volume_gitpod-k3s-lego /mnt/gitpod_k3s_lego
echo '/dev/disk/by-id/scsi-0DO_Volume_gitpod-k3s-lego /mnt/gitpod_k3s_lego ext4 defaults,nofail,discard 0 0' | sudo tee -a /etc/fstab
ln -s /mnt/gitpod_k3s_lego/.lego .lego

if [ -f ".lego/certificates/$DOMAIN.crt" ]; then
    lego --email "$LETS_ENCRYPT_EMAIL" --accept-tos --dns digitalocean -d "$DOMAIN" -d "*.$DOMAIN" -d "*.ws.$DOMAIN" renew
else
    lego --email "$LETS_ENCRYPT_EMAIL" --accept-tos --dns digitalocean -d "$DOMAIN" -d "*.$DOMAIN" -d "*.ws.$DOMAIN" run
fi
mkdir certs
cp ".lego/certificates/$DOMAIN.crt" certs/fullchain.pem
cp ".lego/certificates/$DOMAIN.key" certs/privkey.pem

FULLCHAIN=$(base64 --wrap=0 < certs/fullchain.pem)
PRIVKEY=$(base64 --wrap=0 < certs/privkey.pem)
mkdir -p /var/lib/rancher/k3s/server/manifests/
cat << EOF > /var/lib/rancher/k3s/server/manifests/https-certificates.yaml
apiVersion: v1
kind: Secret
metadata:
  name: https-certificates
  labels:
    app: gitpod
data:
  tls.crt: $FULLCHAIN
  tls.cert: $FULLCHAIN
  tls.key: $PRIVKEY
EOF

cp gitpod-install/calico.yaml /var/lib/rancher/k3s/server/manifests/calico.yaml

# Install and start k3s
export INSTALL_K3S_EXEC="server --disable traefik --node-label gitpod.io/main-node=true --flannel-backend=none --disable-network-policy"
export K3S_CLUSTER_SECRET=qWo6sn3VWERh3dBBQniPLTqtZzEHURsriJNhTqus
export K3S_NODE_NAME=main
curl -sSfL https://get.k3s.io | sh -


# Install helm
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash


# Install Gitpod
sed -i "s/\$DOMAIN/$DOMAIN/g" gitpod-install/values.yaml
sed -i "s/\$GITPOD_GITHUB_CLIENT_SECRET/$GITPOD_GITHUB_CLIENT_SECRET/g" gitpod-install/values.yaml
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
if [ -n "$GITPOD_COMMIT_ID" ]; then
    git clone https://github.com/gitpod-io/gitpod.git
    cd gitpod
    git reset --hard "$GITPOD_COMMIT_ID"
    cd chart
    helm dependency update
    helm install gitpod . --timeout 60m --values ../../gitpod-install/values.yaml
else
    helm repo add gitpod https://charts.gitpod.io
    helm repo update
    if [ -n "$GITPOD_CHART_VERSION" ]; then
        helm install gitpod gitpod/gitpod --timeout 60m --values gitpod-install/values.yaml --version "$GITPOD_CHART_VERSION"
    else
        helm install gitpod gitpod/gitpod --timeout 60m --values gitpod-install/values.yaml
    fi
fi

echo "done"
