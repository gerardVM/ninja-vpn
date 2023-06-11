#!/bin/sh

# Spot Instance Interruption Handler

# Define the action to take when the instance is interrupted
handle_interruption() {
  local instance_id=$1
  
  # Add your custom logic here
  # For example, you could:
  # 1. Gracefully stop any running processes
  # 2. Backup important data or state
  # 3. Send notifications or log the interruption
  
  echo "Spot Instance with ID $instance_id is being interrupted" >> /home/ec2-user/spot-interruption.log
  echo "Taking necessary actions..." >> /home/ec2-user/spot-interruption.log
  
  # Disassociate the Elastic IP from the instance
  aws ec2 disassociate-address --association-id \
  $(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/mac)/association-id)
}

# Main script

# Define variables
TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 1"`
INSTANCE_ID=`curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/instance-id`

# Check if the script is running on a Spot Instance
while true; do
  # Get the token
  TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 1")
  
  # Check if the Spot Instance is being terminated
  if curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/spot/instance-action | grep -q "terminate"; then
  
    # Call the interruption handler function
    handle_interruption "$INSTANCE_ID"
  
    # Add any additional cleanup or termination steps if needed
    # For example, you might want to deregister from a load balancer
  
    # Terminate the instance
    # aws ec2 terminate-instances --instance-ids "$INSTANCE_ID" --region <your-region>
    
    break
  else
    sleep 5
  fi
done