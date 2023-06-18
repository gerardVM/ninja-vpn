#!/bin/sh


# Countdown

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

FLEET_ID=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[].Instances[].Tags[?Key==`aws:ec2spot:fleet-request-id`].Value' --output text)
PAYLOAD=$(echo -n "{\"FLEET_ID\": \"$FLEET_ID\"}" | base64)
aws lambda invoke --function-name ${NAME} --payload $PAYLOAD /home/ec2-user/response.json