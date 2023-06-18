#!/bin/sh


# Install Docker

yum install -y docker zip
systemctl start docker

mkdir -p ${DOCKER_CONFIG}/cli-plugins
curl -SL https://github.com/docker/compose/releases/download/v2.17.2/docker-compose-linux-x86_64 -o ${DOCKER_CONFIG}/cli-plugins/docker-compose
chmod +x ${DOCKER_CONFIG}/cli-plugins/docker-compose
setfacl --modify user:ec2-user:rw /var/run/docker.sock


# Prepare Wireguard configuration and launch it

echo SERVERURL=${SERVERURL} > /home/ec2-user/.env
echo TZ=${TIMEZONE}        >> /home/ec2-user/.env

# aws s3 cp s3://${S3_BUCKET}/$S3_WC_KEY /home/ec2-user/$S3_WC_KEY
# aws kms decrypt --ciphertext-blob fileb://<(base64 -d /home/ec2-user/$S3_WC_KEY) --output text --query Plaintext | base64 -d > /home/ec2-user/wireguard_config.zip
# unzip /home/ec2-user/wireguard_config.zip -d /root/wireguard

aws s3 cp s3://${S3_BUCKET}/${S3_DC_KEY} /home/ec2-user/docker-compose.yaml
aws s3 sync s3://${S3_BUCKET}/${S3_WC_KEY} /root/wireguard/
unzip /home/ec2-user/wireguard_config.zip -d /root/wireguard
docker compose -f /home/ec2-user/docker-compose.yaml up -d
aws s3 rm s3://${S3_BUCKET}/${S3_WC_KEY} --recursive

### PENDING TASKS ####

# MISSING MIGRATING THE WIREGUARD CONFIG FILES AND CHECKING
# WHY LAMBDA STOPS IT INMEDIATELY IF IT'S NOT INVOKED