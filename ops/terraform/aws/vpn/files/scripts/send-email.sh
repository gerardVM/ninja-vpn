#!/bin/sh


# AWS SES send configuration email

aws s3 cp s3://${S3_BUCKET}/${S3_CE_KEY} /home/ec2-user/config_email.txt
cp /root/wireguard/peer1/peer1.conf /home/ec2-user/wg-client.conf
cp /root/wireguard/peer1/peer1.png /home/ec2-user/user-qr.png

export SENDER_EMAIL=${SENDER_EMAIL}
export RECEIVER_EMAIL=${RECEIVER_EMAIL}
export AWS_REGION=${CURRENT_REGION}
export duration=${COUNTDOWN}
export subject="VPN Credentials"
export file_data=$(base64 /home/ec2-user/wg-client.conf)
export image_data=$(base64 /home/ec2-user/user-qr.png)

envsubst '$SENDER_EMAIL,$RECEIVER_EMAIL,$AWS_REGION,$subject,$file_data,$image_data' < /home/ec2-user/config_email.txt > /home/ec2-user/email.txt

aws ses send-raw-email --region ${SES_REGION} --raw-message Data="$(echo -n "$(cat /home/ec2-user/email.txt)" | base64 -w 0)" >> /home/ec2-user/user-data.log