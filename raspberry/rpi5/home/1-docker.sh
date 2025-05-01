#! /bin/sh

if [ -x "$(command -v docker --version)" ]; then
    echo 'Error: docker is installed, exit' >&2
    exit 1
fi

curl -sSL https://get.docker.com | sh

docker version

systemctl stop docker

rm     -rf /var/lib/docker
mkdir      /var/lib/docker
mkdir  -p  /mnt/data/docker

mount --rbind /mnt/data/docker /var/lib/docker
systemctl daemon-reload
systemctl start docker

if ! grep -q 'docker' /etc/fstab ; then
    {
        echo '# docker'
        echo '/mnt/data/docker      /var/lib/docker   none    defaults,bind     0    0'
    } >> /etc/fstab

    echo '/etc/fstab'
fi

echo 'done'