import boto3
import os
import time

def lambda_handler(event, context):

    # Send email notification
    sender_email = os.environ.get('SENDER_EMAIL')
    ses_region = os.environ.get('SES_REGION')
    region = os.environ.get('REGION')
    receiver_email = os.environ.get('RECEIVER_EMAIL')

    destination = {'ToAddresses': [ receiver_email ]}
    source = sender_email
    message = {
        'Subject': {'Data': 'VPN server terminated'},
        'Body': {'Text': {'Data': f'The VPN server in region {region} has been terminated for {receiver_email}.'}}
    }
    
    ses = boto3.client('ses', region_name=ses_region)
    ses.send_email(Destination=destination, Message=message, Source=source)

    time.sleep(50)

    # Terminate the spot ec2 fleet
    fleet_id = event.get('FLEET_ID')

    ec2 = boto3.client('ec2')
    ec2.cancel_spot_fleet_requests(SpotFleetRequestIds=[fleet_id], TerminateInstances=True)

    # Release the elastic IP address
    eip_id = os.environ.get('EIP_ID')

    eip = boto3.client('ec2')
    eip.release_address(AllocationId=eip_id)

    return 'Success'