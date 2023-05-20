import boto3
import os

def lambda_handler(event, context):

    # Terminate the instance
    ec2 = boto3.client('ec2')
    instance_id = os.environ.get('INSTANCE_ID')
    ec2.terminate_instances(InstanceIds=[instance_id])

    # Release the elastic IP address
    eip = boto3.client('ec2')
    eip_id = os.environ.get('EIP_ID')
    eip.release_address(AllocationId=eip_id)

    # Send email notification
    ses = boto3.client('ses')
    email_address = os.environ.get('EMAIL_ADDRESS')
    destination = {'ToAddresses': [ email_address ]}
    message = {
        'Subject': {'Data': 'VPN server terminated'},
        'Body': {'Text': {'Data': 'The VPN server has been terminated'}}
    }
    source = email_address
    ses.send_email(Destination=destination, Message=message, Source=source)

    return 'Success'