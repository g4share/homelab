#!/bin/sh
set -eu
. "$(dirname "$0")/setup-helpers.sh"

if [ "$(id -u)" -ne 0 ]; then
    echo "Run this script with sudo." >&2
    exit 1
fi

if ! mountpoint -q /mnt/data; then
    echo "Error: /mnt/data is not mounted. Run 0-setup.sh first." >&2
    exit 1
fi

if [ ! -d /mnt/data/volumes/torrent/data ]; then
    echo "Error: torrent data directory is missing. Run 2-portainer.sh first." >&2
    exit 1
fi

export DEBIAN_FRONTEND=noninteractive
apt-get install -y samba samba-common-bin

mkdir -p /mnt/data/shared
chmod -R 777 /mnt/data/shared

ensure_samba_share shared /mnt/data/shared Yes Yes 0666 0777
ensure_samba_share torrent /mnt/data/volumes/torrent/data/ No Yes

if ! testparm -s /etc/samba/smb.conf >/dev/null; then
    echo "Error: Samba configuration is invalid." >&2
    exit 1
fi

systemctl restart smbd
if ! systemctl is-active --quiet smbd; then
    echo "Error: Samba service is not running." >&2
    exit 1
fi

echo "done"
