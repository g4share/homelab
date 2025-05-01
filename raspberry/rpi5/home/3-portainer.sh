#! /bin/sh

docker pull portainer/portainer-ee:latest
docker run -d -p 9000:9000 --name=portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ee:latest

mkdir -p /mnt/data/volumes/torrent/config
mkdir -p /mnt/data/volumes/torrent/data

mkdir -p /mnt/data/volumes/file-browser/config
touch    /mnt/data/volumes/file-browser/config/database.db
mkdir -p /mnt/data/volumes/file-browser/data

echo 'done'
