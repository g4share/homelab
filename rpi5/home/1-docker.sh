#!/bin/sh
set -eu
. "$(dirname "$0")/setup-helpers.sh"
data_mount="/mnt/data"
docker_data_path="$data_mount/docker"

usage() {
    echo "Usage: sudo $0 -u <data-partition-UUID>" >&2
    echo " Find UUIDs with: lsblk -f" >&2
    echo " Use the UUID from the data partition row." >&2
    echo " Example: sudo $0 -u 972dfba6-0ad6-4347-8d63-2795d7a0d8fd" >&2
    exit 1
}

# Require root privileges.
if [ "$(id -u)" -ne 0 ]; then
    echo "Run this script with sudo." >&2
    usage
fi

while getopts ":u:" opt; do
    case "$opt" in
        u) disk_uuid="$OPTARG" ;;
        :) usage ;;
        \?) usage ;;
    esac
done
shift $((OPTIND - 1))

if [ -z "${disk_uuid:-}" ] || [ "$#" -ne 0 ]; then
    usage
fi

# Accept the UUID with or without the UUID= prefix.
disk_uuid="${disk_uuid#UUID=}"
disk_source="UUID=$disk_uuid"

# Resolve the UUID and detect the filesystem type on that partition.
if ! disk_device="$(findfs "$disk_source" 2>/dev/null)"; then
    echo "Filesystem UUID not found: $disk_source" >&2
    exit 1
fi
if ! disk_fstype="$(blkid -o value -s TYPE "$disk_device")" || [ -z "$disk_fstype" ]; then
    echo "Could not determine filesystem type for $disk_source" >&2
    exit 1
fi

ensure_mount "$data_mount" "$disk_uuid"
ensure_fstab_entry "$docker_data_path" /var/lib/docker none bind 0 0 "docker bind"
mkdir -p "$docker_data_path"

if systemctl is-active --quiet docker; then
    systemctl stop docker
fi
if mountpoint -q /var/lib/docker; then
    umount /var/lib/docker
fi
ensure_mount /var/lib/docker "$disk_uuid"

export DEBIAN_FRONTEND=noninteractive
install_docker

groupadd -f docker
usermod -aG docker "$SUDO_USER"

if ! systemctl enable --now docker; then
    echo "Error: Docker service could not be enabled and started." >&2
    exit 1
fi
if ! systemctl is-active --quiet docker; then
    echo "Error: Docker service is not active." >&2
    exit 1
fi
docker_root="$(docker info --format '{{.DockerRootDir}}')"
if [ "$docker_root" != "/var/lib/docker" ]; then
    echo "Error: Docker is using unexpected data root: $docker_root" >&2
    exit 1
fi

echo "Docker is installed and uses $docker_data_path via /var/lib/docker."
echo "Log out and back in as $SUDO_USER for docker group access to take effect."
echo "done"
