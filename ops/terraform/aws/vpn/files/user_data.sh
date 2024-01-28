#!/bin/sh

# Associate Elastic IP

TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 1"`
export INSTANCE_ID=`curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/instance-id`
aws ec2 associate-address --instance-id $INSTANCE_ID --allocation-id ${EIP_ID}


# Bring all the scripts

mkdir -p /home/ec2-user/scripts
aws s3 cp s3://${S3_BUCKET}/${S3_TH_KEY} /home/ec2-user/scripts/termination_handler.sh
aws s3 cp s3://${S3_BUCKET}/${S3_IV_KEY} /home/ec2-user/scripts/install-vpn.sh
aws s3 cp s3://${S3_BUCKET}/${S3_SE_KEY} /home/ec2-user/scripts/send-email.sh


# Export all necessary variables

export NAME="${NAME}"   
export CURRENT_REGION="${CURRENT_REGION}"      
export SERVERURL="${SERVERURL}"           
export TIMEZONE="${TIMEZONE}"            
export DOCKER_CONFIG="${DOCKER_CONFIG}" 
export S3_BUCKET="${S3_BUCKET}" 
export S3_DC_KEY="${S3_DC_KEY}" 
export S3_CE_KEY="${S3_CE_KEY}" 
export S3_WC_KEY="${S3_WC_KEY}" 
export SENDER_EMAIL="${SENDER_EMAIL}" 
export RECEIVER_EMAIL="${RECEIVER_EMAIL}" 
export SES_REGION="${SES_REGION}"


# Spot Instance Interruption Handler

/bin/bash /home/ec2-user/scripts/termination_handler.sh &


# Install VPN

/bin/bash /home/ec2-user/scripts/install-vpn.sh


# Continue execution just if this is the first run

if [ -f /home/ec2-user/first_run.txt ]; then

    # Send email

    /bin/bash /home/ec2-user/scripts/send-email.sh

fi