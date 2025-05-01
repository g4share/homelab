#! /bin/sh

help() {
   echo "Usage: $0 -d {diskName}"
   exit 1
}

while getopts "d:" opt; do
   case "$opt" in
      d ) diskName="$OPTARG" ;;
      ? ) help ;;
   esac
done

if [ -z "$diskName" ] ; then
   help
fi

apt update; apt upgrade -y;

# vim
apt remove vim-tiny -y;
apt purge vim-tiny -y;
apt install vim -y;

# mc
sudo apt install mc -y

# speedtest by ookla
if ! [ -x "$(command -v speedtest -V)" ]; then
    echo '>>> speedtest'
    curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | sudo bash
    apt install speedtest
fi

if ! grep -q 'data' /etc/fstab ; then
    {
        echo '#'
        echo '# data'
        echo "$diskName             /mnt/data       ext4    defaults          0       2"
    } >> /etc/fstab

    echo '/etc/fstab'
fi

echo 'done'