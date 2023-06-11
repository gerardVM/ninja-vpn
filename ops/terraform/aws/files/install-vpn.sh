#!/bin/sh

# Associate Elastic IP

TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 1"`
INSTANCE_ID=`curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/instance-id`
aws ec2 associate-address --instance-id $INSTANCE_ID --allocation-id ${EIP_ID}


# Spot Instance Interruption Handler

cp s3 cp s3://${S3_BUCKET}/${S3_TS_KEY} /home/ec2-user/termination_script.sh
chmod +x /home/ec2-user/termination_script.sh
/bin/bash /home/ec2-user/termination_script.sh &


# Install Docker

yum install -y docker
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

aws s3 cp s3://${S3_BUCKET}/${S3_DC_KEY} /home/ec2-user/docker-compose.yaml &&
docker compose -f /home/ec2-user/docker-compose.yaml up -d


# AWS SES configuration email

while [[ $(aws ses get-identity-verification-attributes --region ${SES_REGION} --identities ${SENDER_EMAIL} | grep VerificationStatus | awk '{print $2}' | tr -d '"') != "Success" ]] ||
      [[ $(aws ses get-identity-verification-attributes --region ${SES_REGION} --identities ${RECEIVER_EMAIL} | grep VerificationStatus | awk '{print $2}' | tr -d '"') != "Success" ]] ; do
    sleep 5
done

aws s3 cp s3://${S3_BUCKET}/${S3_CE_KEY} /home/ec2-user/config_email.txt
cp /root/wireguard/peer1/peer1.conf /home/ec2-user/wg-client.conf
cp /root/wireguard/peer1/peer1.png /home/ec2-user/user-qr.png

export SENDER_EMAIL=${SENDER_EMAIL}
export RECEIVER_EMAIL=${RECEIVER_EMAIL}
export AWS_REGION=${CURRENT_REGION}
export subject="VPN Credentials"
export file_data=$(base64 /home/ec2-user/wg-client.conf)
export image_data=$(base64 /home/ec2-user/user-qr.png)

envsubst '$SENDER_EMAIL,$RECEIVER_EMAIL,$AWS_REGION,$subject,$file_data,$image_data' < /home/ec2-user/config_email.txt > /home/ec2-user/email.txt

aws ses send-raw-email --region ${SES_REGION} --raw-message Data="$(echo -n "$(cat /home/ec2-user/email.txt)" | base64 -w 0)"

# Managing the instance lifecycle

if [[ "${COUNTDOWN}" != "0" ]]; then

  convert_to_seconds() (

    local value=$(echo $1 | cut -d' ' -f1)
    local type=$(echo $1 | cut -d' ' -f2)

    case $type in
        second*)
        seconds=$value
        ;;
        minute*)
        seconds=$((value * 60))
        ;;
        hour*)
        seconds=$((value * 60 * 60))
        ;;
        day*)
        seconds=$((value * 60 * 60 * 24))
        ;;
        *)
        echo "Invalid type. Supported types: seconds, minutes, hours, days."
        return 1
        ;;
    esac

    echo $seconds

  )

sleep $(convert_to_seconds "${COUNTDOWN}") # This need to be adapted to the case of a instance termination

PAYLOAD=$(echo -n "{\"INSTANCE_ID\": \"$INSTANCE_ID\"}" | base64)
aws lambda invoke --function-name ${NAME} --payload $PAYLOAD /home/ec2-user/response.json

fi