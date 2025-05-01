#! /bin/sh

apt update; apt upgrade -y;

docker stop portainer_agent
docker rm portainer_agent

docker rmi portainer/agent:latest
docker pull portainer/agent:latest
docker run -d -p 9001:9001 --name portainer_agent --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v /var/lib/docker/volumes:/var/lib/docker/volumes -v /:/host portainer/agent:latest

echo 'done'