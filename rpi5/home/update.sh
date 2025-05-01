#!/bin/sh
set -eu
. "$(dirname "$0")/setup-helpers.sh"

if [ "$(id -u)" -ne 0 ]; then
    echo "Run this script with sudo." >&2
    exit 1
fi

if ! docker info >/dev/null 2>&1; then
    echo "Docker is not running." >&2
    exit 1
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get upgrade -y

install_or_update_container portainer portainer/portainer-ee:latest \
    -p 9000:9000 \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v portainer_data:/data

install_or_update_container portainer_agent portainer/agent:latest \
    -p 9001:9001 \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v /var/lib/docker/volumes:/var/lib/docker/volumes \
    -v /:/host

echo "done"
