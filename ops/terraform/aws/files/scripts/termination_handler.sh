#!/bin/sh

# Spot Instance Interruption Handler

# Define the action to take when the instance is interrupted
handle_interruption() {
  local instance_id=$1
  
  echo -e "Spot Instance with ID $instance_id is being interrupted. Taking necessary actions..."

  # Disassociate the Elastic IP from the instance

  ASSOCIATION_ID=$(aws ec2 describe-addresses --filters "Name=instance-id,Values=$instance_id" --query 'Addresses[*].AssociationId' --output text)
  aws ec2 disassociate-address --association-id $ASSOCIATION_ID
  echo -e "Disassociated Elastic IP from instance $instance_id"

  # Syncronize the files to S3
  aws s3 sync /root/wireguard/ s3://${S3_BUCKET}/${S3_WC_KEY} --delete
}


# Main script

while true; do
  # Get the token
  TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 1")
  
  # Check if the Spot Instance is being terminated
  if curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/spot/instance-action | grep -q "terminate"; then

    # Call the interruption handler function
    handle_interruption `curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/instance-id` >> /home/ec2-user/spot-interruption.log
    
    break
  else
    sleep 5
  fi
done