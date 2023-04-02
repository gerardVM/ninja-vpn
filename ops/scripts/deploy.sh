#!/bin/sh

export ADDRESS=$(terraform output public_dns | tr -d '"')
export TIMEZONE=$(cat ../../../config.yaml | grep my_timezone | awk '{print $2}' | tr -d '"')

envsubst < ${DOCKER_DIR}/docker-compose.yaml > ${DOCKER_DIR}/docker-compose_updated.yaml

sleep 5

scp -i ${SSH_DIR}/id_rsa \
-o "StrictHostKeyChecking no" \
-o "UserKnownHostsFile=/dev/null" \
 ${SCRIPTS_DIR}/install-vpn.sh ec2-user@${ADDRESS}:/home/ec2-user/install-vpn.sh

scp -i ${SSH_DIR}/id_rsa \
-o "StrictHostKeyChecking no" \
-o "UserKnownHostsFile=/dev/null" \
 ${DOCKER_DIR}/docker-compose_updated.yaml ec2-user@${ADDRESS}:/home/ec2-user/docker-compose.yaml

ssh -i ${SSH_DIR}/id_rsa \
-o "StrictHostKeyChecking no" \
-o "UserKnownHostsFile=/dev/null" \
 ec2-user@${ADDRESS} "chmod +x /home/ec2-user/install-vpn.sh && /home/ec2-user/install-vpn.sh"

ssh -i ${SSH_DIR}/id_rsa \
-o "StrictHostKeyChecking no" \
-o "UserKnownHostsFile=/dev/null" \
ec2-user@${ADDRESS} "docker exec wireguard cat /config/peer1/peer1.conf" \
> ../../../wireguard.conf