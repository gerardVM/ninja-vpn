import boto3

def lambda_handler(event, context):

    # Terminate the instance
    ec2 = boto3.client('ec2')
    instance_id = event['instance_id']
    ec2.terminate_instances(InstanceIds=[instance_id])

    # Release the elastic IP address
    eip = boto3.client('ec2')
    eip_id = event['eip_id']
    eip.release_address(AllocationId=eip_id)

    # Identify the event rule
    events = boto3.client('events')
    rule_id = event['rule_id']

    # Get the IDs of all targets associated with the rule
    response1 = events.list_targets_by_rule(Rule=rule_id)
    target_ids = [target['Id'] for target in response1['Targets']]

    # Remove all targets from the rule
    if target_ids:
        response2 = events.remove_targets(Rule=rule_id, Ids=target_ids)

    # Delete the event rule
    response3 = events.delete_rule(Name=rule_id)

    # Send email notification
    ses = boto3.client('ses')
    email_address = event['email_address']
    destination = {'ToAddresses': [ email_address ]}
    message = {
        'Subject': {'Data': 'VPN server terminated'},
        'Body': {'Text': {'Data': 'The VPN server has been terminated'}}
    }
    source = email_address
    ses.send_email(Destination=destination, Message=message, Source=source)

    return 'Success'