[![Gitpod ready-to-code](https://img.shields.io/badge/Gitpod-ready--to--code-blue?logo=gitpod)](https://gitpod.io/#https://github.com/corneliusludmann/gitpod-k3s-droplet)

# Gitpod on Digital Ocean Droplets

This is a proof of concept that installs [k3s](https://k3s.io/) and [Gitpod](http://gitpod.io/) on 2 VMs ([Digtial Ocean Droplets](https://www.digitalocean.com/products/droplets/)).

Just run `./digitalocean-droplet/setup.sh` to setup and `./digitalocean-droplet/teardown.sh` to teardown.

The following environement variables are needed:

| Environment Variable               | Explanation                                               |
|------------------------------------|-----------------------------------------------------------|
| `DIGITALOCEAN_ACCESS_TOKEN`        | Access token for Digital Ocean                            |
| `DIGITALOCEAN_SSH_KEY`             | Base64 encoded SSH key (content of `.ssh/id_rsa`)         |
| `DIGITALOCEAN_SSH_PUBKEY`          | Base64 encoded SSH pub key (content of `.ssh/id_rsa.pub`) |
| `DIGITALOCEAN_SSH_KEY_FINGERPRINT` | Fingerprint of SSH key in Digital Ocean                   |
| `GITPOD_GITHUB_CLIENT_SECRET`      | GitHub Client Secret of the Gitpod app                    |

You also need a [Digital Ocean account](https://digitalocean.com) with a configured [domain](https://cloud.digitalocean.com/networking/domains) (here `ludmann.name`) and [SSH key](https://cloud.digitalocean.com/account/security).
