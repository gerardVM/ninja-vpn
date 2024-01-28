#!/bin/sh


# AWS SES send configuration email

aws s3 cp s3://${S3_BUCKET}/${S3_CE_KEY} /home/ec2-user/config_email.txt
cp /root/wireguard/peer1/peer1.conf /home/ec2-user/wg-client.conf
cp /root/wireguard/peer1/peer1.png /home/ec2-user/user-qr.png

export SENDER_EMAIL=${SENDER_EMAIL}
export RECEIVER_EMAIL=${RECEIVER_EMAIL}
export AWS_REGION=${CURRENT_REGION}
export duration_seconds=${COUNTDOWN}
export subject="VPN Credentials"
export file_data=$(base64 /home/ec2-user/wg-client.conf)
export image_data=$(base64 /home/ec2-user/user-qr.png)


# Convert duration to human readable format

convert_seconds() {
    local seconds=$1
    local minutes=0
    local hours=0

    if [ $seconds -ge 3600 ]; then
        hours=$((seconds / 3600))
        seconds=$((seconds % 3600))
    fi

    if [ $seconds -ge 60 ]; then
        minutes=$((seconds / 60))
        seconds=$((seconds % 60))
    fi

    if [ $hours -gt 0 ]; then
        if [ $minutes -gt 0 ]; then
            echo "${hours} hours ${minutes} minutes"
        else
            echo "${hours} hours"
        fi
    elif [ $minutes -gt 0 ]; then
        echo "${minutes} minutes"
    fi
}

export duration=$(convert_seconds $duration_seconds)


# Replace variables in email template and send email

envsubst '$SENDER_EMAIL,$RECEIVER_EMAIL,$AWS_REGION,$duration,$subject,$file_data,$image_data' < /home/ec2-user/config_email.txt > /home/ec2-user/email.txt

aws ses send-raw-email --region ${SES_REGION} --raw-message Data="$(echo -n "$(cat /home/ec2-user/email.txt)" | base64 -w 0)" >> /home/ec2-user/user-data.log
