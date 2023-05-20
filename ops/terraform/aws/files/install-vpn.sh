#!/bin/sh

# Install Docker and Compose Wireguard VPN

yum install -y docker qrencode
systemctl start docker

mkdir -p ${DOCKER_CONFIG}/cli-plugins
curl -SL https://github.com/docker/compose/releases/download/v2.17.2/docker-compose-linux-x86_64 -o ${DOCKER_CONFIG}/cli-plugins/docker-compose
chmod +x ${DOCKER_CONFIG}/cli-plugins/docker-compose
setfacl --modify user:ec2-user:rw /var/run/docker.sock

echo SERVERURL=${SERVERURL} > /home/ec2-user/.env
echo TZ=${TIMEZONE}        >> /home/ec2-user/.env

aws s3 cp s3://${S3_BUCKET}/${S3_DC_KEY} /home/ec2-user/docker-compose.yaml &&
docker compose -f /home/ec2-user/docker-compose.yaml up -d

# AWS SES configuration email

while [[ $(aws ses get-identity-verification-attributes --identities ${EMAIL_ADDRESS} | grep VerificationStatus | awk '{print $2}' | tr -d '"') != "Success" ]]; do
    sleep 5
done

aws s3 cp s3://${S3_BUCKET}/${S3_CE_KEY} /home/ec2-user/config_email.txt
docker exec wireguard cat /config/peer1/peer1.conf > /home/ec2-user/wg-client.conf
qrencode -t png -o /home/ec2-user/user-qr.png -r /home/ec2-user/wg-client.conf

export EMAIL_ADDRESS=${EMAIL_ADDRESS}
export subject="VPN Credentials"
export file_data=$(base64 /home/ec2-user/wg-client.conf)
export image_data=$(base64 /home/ec2-user/user-qr.png)

envsubst '$EMAIL_ADDRESS,$subject,$file_data,$image_data' < /home/ec2-user/config_email.txt > /home/ec2-user/email.txt

aws ses send-raw-email --raw-message Data="$(echo -n "$(cat /home/ec2-user/email.txt)" | base64 -w 0)"

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

sleep $(convert_to_seconds "${COUNTDOWN}")

aws lambda invoke --function-name ${NAME} response.json  

fi