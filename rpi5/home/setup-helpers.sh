# Shared setup helpers used by the setup scripts.
# This file is sourced by the setup scripts; it is not run directly.

# Ensure one fstab entry exists with the requested values.
# Arguments: source target type options dump pass comment
ensure_fstab_entry() {
    entry_source="$1"
    entry_target="$2"
    entry_type="$3"
    entry_options="$4"
    entry_dump="$5"
    entry_pass="$6"
    entry_comment="$7"

    entry_state="$(awk -v source="$entry_source" -v target="$entry_target" \
        -v type="$entry_type" -v options="$entry_options" \
        -v dump="$entry_dump" -v pass="$entry_pass" \
        '$2 == target && $0 !~ /^[[:space:]]*#/ {
             found = 1
             if ($1 == source && $3 == type && $4 == options && $5 == dump && $6 == pass) correct = 1
         }
         END {
             if (!found) print "missing"
             else if (correct) print "correct"
             else print "incorrect"
         }' /etc/fstab)"

    case "$entry_state" in
        correct)
            echo "/etc/fstab already has the requested entry for $entry_target."
            ;;
        missing)
            if [ -z "${fstab_backup:-}" ]; then
                fstab_backup="$(mktemp /etc/fstab.bak.XXXXXX)"
                cp -a /etc/fstab "$fstab_backup"
            fi
            if [ -n "$entry_comment" ]; then
                printf '# %s\n' "$entry_comment" >> /etc/fstab
            fi
            printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
                "$entry_source" "$entry_target" "$entry_type" "$entry_options" \
                "$entry_dump" "$entry_pass" >> /etc/fstab
            echo "Added $entry_source to /etc/fstab for $entry_target."
            ;;
        incorrect)
            echo "Error: /etc/fstab has an incorrect entry for $entry_target; leaving it unchanged." >&2
            return 1
            ;;
        *)
            echo "Error: could not check the /etc/fstab entry for $entry_target." >&2
            return 1
            ;;
    esac
}

# Create a mount point, mount it from fstab if needed, and verify its UUID.
# Arguments: mount point UUID
ensure_mount() {
    mount_path="$1"
    expected_uuid="$2"

    if ! systemctl daemon-reload; then
        echo "Error: systemd could not reload mount configuration." >&2
        return 1
    fi

    mkdir -p "$mount_path"
    findmnt --verify --verbose

    if ! mountpoint -q "$mount_path" && ! mount "$mount_path"; then
        echo "Error: could not mount $mount_path using /etc/fstab." >&2
        return 1
    fi
    if ! mountpoint -q "$mount_path"; then
        echo "Error: $mount_path is not mounted." >&2
        return 1
    fi

    mounted_uuid="$(findmnt -n -o UUID -M "$mount_path" 2>/dev/null || true)"
    if [ "$mounted_uuid" != "$expected_uuid" ]; then
        echo "Error: $mount_path is mounted from a different filesystem UUID (${mounted_uuid:-unknown})." >&2
        return 1
    fi
}

# Read one expected signing-key fingerprint from the plain-text config file.
# Usage: get_fingerprint OOKLA_PRIMARY_FINGERPRINT
get_fingerprint() {
    fingerprint_name="$1"
    fingerprints_file="$(dirname "$0")/repo-fingerprints.conf"

    if [ ! -f "$fingerprints_file" ] || [ ! -r "$fingerprints_file" ]; then
        echo "Required fingerprint file is missing or unreadable: $fingerprints_file" >&2
        return 1
    fi

    # Read the named value without sourcing the config as shell code.
    fingerprint="$(awk -F= -v name="$fingerprint_name" \
        '$1 == name { print $2; exit }' "$fingerprints_file")"
    if [ -z "$fingerprint" ]; then
        echo "Required fingerprint $fingerprint_name is missing from $fingerprints_file." >&2
        return 1
    fi

    printf '%s\n' "$fingerprint"
}

# Load Debian's release codename for the repository configuration.
load_release_codename() {
    if [ ! -r /etc/os-release ]; then
        echo "Cannot read /etc/os-release." >&2
        return 1
    fi

    . /etc/os-release
    if [ -z "${VERSION_CODENAME:-}" ]; then
        echo "Could not determine the Debian release codename." >&2
        return 1
    fi
}

# Download, verify, and install a repository key using its expected fingerprint.
# Usage: install_verified_apt_key <url> <fingerprint> <keyring-path> <name>
install_verified_apt_key() {
    key_url="$1"
    expected_key_fingerprint="$2"
    keyring_path="$3"
    repository_name="$4"
    key_tmp="$(mktemp)"

    if ! curl -fsSL "$key_url" -o "$key_tmp"; then
        rm -f "$key_tmp"
        echo "Could not download the $repository_name APT signing key." >&2
        return 1
    fi

    # Check the primary key fingerprint before installing the key.
    if ! actual_key_fingerprint="$(gpg --show-keys --with-colons --with-fingerprint "$key_tmp" \
        | awk -F: '$1 == "pub" { primary = 1; next } primary && $1 == "fpr" { print toupper($10); exit }')"; then
        rm -f "$key_tmp"
        echo "Could not read the $repository_name signing-key fingerprint." >&2
        return 1
    fi
    if [ "$actual_key_fingerprint" != "$expected_key_fingerprint" ]; then
        rm -f "$key_tmp"
        echo "$repository_name signing-key fingerprint does not match the expected value." >&2
        return 1
    fi

    if ! gpg --dearmor --yes --output "$keyring_path" "$key_tmp"; then
        rm -f "$key_tmp"
        echo "Could not install the $repository_name APT signing key." >&2
        return 1
    fi
    rm -f "$key_tmp"
    chmod a+r "$keyring_path"
}

# Add the Ookla APT repository and install Speedtest if it is not installed.
# The downloaded signing key is checked against repo-fingerprints.conf first.
install_speedtest() {
    if command -v speedtest >/dev/null 2>&1; then
        echo "Speedtest is already installed."
        return
    fi

    echo ">>> Installing Ookla Speedtest"
    if ! expected_ookla_primary_fingerprint="$(get_fingerprint OOKLA_PRIMARY_FINGERPRINT)"; then
        exit 1
    fi

    if ! load_release_codename; then
        exit 1
    fi

    apt-get install -y gnupg
    install -m 0755 -d /etc/apt/keyrings
    if ! install_verified_apt_key \
        https://packagecloud.io/ookla/speedtest-cli/gpgkey \
        "$expected_ookla_primary_fingerprint" \
        /etc/apt/keyrings/ookla_speedtest-cli-archive-keyring.gpg \
        Ookla; then
        exit 1
    fi

    printf 'deb [signed-by=/etc/apt/keyrings/ookla_speedtest-cli-archive-keyring.gpg] https://packagecloud.io/ookla/speedtest-cli/debian/ %s main\n' \
        "$VERSION_CODENAME" > /etc/apt/sources.list.d/ookla_speedtest-cli.list

    if ! apt-get update; then
        echo "Error: apt could not refresh package lists after adding the Ookla repository." >&2
        exit 1
    fi
    if ! apt-get install -y speedtest; then
        echo "Error: could not install the Speedtest package." >&2
        exit 1
    fi
    if ! command -v speedtest >/dev/null 2>&1; then
        echo "Error: Speedtest package installed, but the speedtest command is unavailable." >&2
        exit 1
    fi
}

# Add Docker's official Debian APT repository and install Docker Engine.
# The downloaded signing key is checked against repo-fingerprints.conf first.
# This function only installs Docker; 1-docker.sh configures its data mount
# and grants the invoking user access to the docker group.
install_docker() {
    if [ "$(dpkg-query -W -f='${db:Status-Status}' docker-ce 2>/dev/null || true)" = "installed" ]; then
        echo "Docker Engine is already installed."
        return
    fi

    if command -v docker >/dev/null 2>&1; then
        echo "A docker command exists, but docker-ce is not installed. Resolve the existing Docker package before continuing." >&2
        exit 1
    fi

    if ! expected_docker_fingerprint="$(get_fingerprint DOCKER_PRIMARY_FINGERPRINT)"; then
        exit 1
    fi

    if ! load_release_codename; then
        exit 1
    fi
    docker_arch="$(dpkg --print-architecture)"

    apt-get update
    apt-get install -y ca-certificates curl gnupg

    install -m 0755 -d /etc/apt/keyrings
    if ! install_verified_apt_key \
        https://download.docker.com/linux/debian/gpg \
        "$expected_docker_fingerprint" \
        /etc/apt/keyrings/docker.gpg \
        Docker; then
        exit 1
    fi

    cat > /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: $VERSION_CODENAME
Components: stable
Architectures: $docker_arch
Signed-By: /etc/apt/keyrings/docker.gpg
EOF

    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io \
        docker-buildx-plugin docker-compose-plugin
}

# Install or refresh one container, then verify that it is running.
# Arguments: container name image docker-run-options...
install_or_update_container() {
    container_name="$1"
    container_image="$2"
    shift 2

    if ! docker pull "$container_image"; then
        echo "Error: could not pull $container_image." >&2
        return 1
    fi

    if docker container inspect "$container_name" >/dev/null 2>&1; then
        if [ "$(docker container inspect --format '{{.State.Running}}' "$container_name")" = "true" ]; then
            if ! docker container stop "$container_name" >/dev/null; then
                echo "Error: could not stop $container_name." >&2
                return 1
            fi
        fi
        if ! docker container rm "$container_name" >/dev/null; then
            echo "Error: could not remove $container_name." >&2
            return 1
        fi
    fi

    if ! docker run -d \
        --name "$container_name" \
        --restart always \
        "$@" \
        "$container_image"; then
        echo "Error: could not create $container_name." >&2
        return 1
    fi

    if [ "$(docker container inspect --format '{{.State.Running}}' "$container_name")" != "true" ]; then
        echo "Error: $container_name is not running." >&2
        return 1
    fi

    echo "$container_name is running."
}

# Add a Samba share if its section is not already in smb.conf.
# Arguments: name path writeable public [create-mask directory-mask]
ensure_samba_share() {
    share_name="$1"
    share_path="$2"
    share_writeable="$3"
    share_public="$4"
    share_create_mask="${5:-}"
    share_directory_mask="${6:-}"

    if grep -Fqx "[$share_name]" /etc/samba/smb.conf; then
        echo "Samba share [$share_name] already exists."
        return
    fi

    {
        printf '\n[%s]\n' "$share_name"
        printf 'path = %s\n' "$share_path"
        printf 'writeable=%s\n' "$share_writeable"
        if [ -n "$share_create_mask" ]; then
            printf 'create mask=%s\n' "$share_create_mask"
            printf 'directory mask=%s\n' "$share_directory_mask"
        fi
        printf 'public=%s\n' "$share_public"
    } >> /etc/samba/smb.conf

    echo "Added Samba share [$share_name]."
}
