#!/bin/sh


# countdown

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

FLEET_ID=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[].Instances[].Tags[?Key==`aws:ec2spot:fleet-request-id`].Value' --output text)
PAYLOAD=$(echo -n "{\"FLEET_ID\": \"$FLEET_ID\"}" | base64)
aws lambda invoke --function-name ${NAME} --payload $PAYLOAD /home/ec2-user/response.json

aws ec2 cancel-spot-fleet-requests --terminate-instances --spot-fleet-request-ids sfr-43a1fb03-cf4b-4cd9-8bce-11b2b09e82bd