#!/bin/sh
set -eu
. "$(dirname "$0")/setup-helpers.sh"

if [ "$(id -u)" -ne 0 ]; then
    echo "Run this script with sudo." >&2
    exit 1
fi

if ! docker info >/dev/null 2>&1; then
    echo "Docker is not running. Run 1-docker.sh first." >&2
    exit 1
fi

# Create the shared service account and group if needed.
if ! getent group dockerfiles >/dev/null 2>&1; then
    groupadd -g 2000 dockerfiles
fi
if ! id dockerfiles >/dev/null 2>&1; then
    useradd -u 2000 -g dockerfiles -M -s /usr/sbin/nologin dockerfiles
fi

# qBittorrent data directories.
if [ ! -d /mnt/data/volumes/torrent ]; then
    mkdir -p \
        /mnt/data/volumes/torrent/config \
        /mnt/data/volumes/torrent/scripts \
        /mnt/data/volumes/torrent/data
    chown -R 2000:2000 /mnt/data/volumes/torrent
fi

# File Browser data directories.
if [ ! -d /mnt/data/volumes/file-browser ]; then
    mkdir -p \
        /mnt/data/volumes/file-browser/config \
        /mnt/data/volumes/file-browser/database \
        /mnt/data/volumes/file-browser/data
    chown -R 2000:2000 /mnt/data/volumes/file-browser
fi

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
