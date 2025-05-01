#! /bin/sh

apt update; apt upgrade -y;

docker stop portainer
docker rm portainer

docker rmi portainer/portainer-ee:latest

docker pull portainer/portainer-ee
docker run -d -p 9000:9000 --name=portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ee:latest

echo 'done'