#!/bin/sh

sudo yum install -y docker
sudo systemctl start docker

DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
mkdir -p $DOCKER_CONFIG/cli-plugins
curl -SL https://github.com/docker/compose/releases/download/v2.17.2/docker-compose-linux-x86_64 -o $DOCKER_CONFIG/cli-plugins/docker-compose
sudo chmod +x $DOCKER_CONFIG/cli-plugins/docker-compose
sudo setfacl --modify user:ec2-user:rw /var/run/docker.sock

docker compose up -d
sleep 5
docker logs wireguard