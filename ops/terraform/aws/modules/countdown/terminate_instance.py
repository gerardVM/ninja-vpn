import boto3

def lambda_handler(event, context):

    # Terminate the instance
    ec2 = boto3.client('ec2')
    instance_id = event['instance_id']
    ec2.terminate_instances(InstanceIds=[instance_id])
    
    # Delete the event rule
    events = boto3.client('events')
    rule_id = event['rule_id']

    # Get the IDs of all targets associated with the rule
    response1 = events.list_targets_by_rule(Rule=rule_id)
    target_ids = [target['Id'] for target in response1['Targets']]

    # Remove all targets from the rule
    if target_ids:
        response2 = events.remove_targets(Rule=rule_id, Ids=target_ids)

    # Delete the rule
    response3 = events.delete_rule(Name=rule_id)

    return 'Instance terminated'