import boto3
import os
import random
import string

def generate_random_hex_value(length=32):
    characters = string.hexdigits + '_%@'
    random_value = ''.join(random.choice(characters) for _ in range(length))
    return random_value

def rotate_ssm_parameter(parameter_name):
    ssm = boto3.client('ssm')

    # Get the current value of the parameter
    response = ssm.get_parameter(Name=parameter_name, WithDecryption=True)
    current_value = response['Parameter']['Value']

    # Generate a new value
    new_value = generate_random_hex_value()

    # Update the parameter value
    ssm.put_parameter(
        Name=parameter_name,
        Value=new_value,
        Type='SecureString',
        Overwrite=True
    )

    return {
        'message': 'Parameter rotation successful',
        'old_value': current_value,
        'new_value': new_value
    }

def update_cloudfront_origin_header(distribution_id, origin_id, custom_header_name, custom_header_value):
    cloudfront = boto3.client('cloudfront')

    response = cloudfront.get_distribution(Id=distribution_id)
    distribution_config = response['Distribution']['DistributionConfig']
    
    for origin in distribution_config['Origins']['Items']:
        if origin['Id'] == origin_id:
            origin['CustomHeaders']['Items'] = [
                {
                    'HeaderName': custom_header_name,
                    'HeaderValue': custom_header_value
                }
            ]
    
    response = cloudfront.update_distribution(
        Id=distribution_id,
        IfMatch=response['ETag'],
        DistributionConfig=distribution_config
    )

def lambda_handler(event, context):
    parameter_name = os.environ.get('SSM_PARAMETER_NAME')
    distribution_id = os.environ.get('CLOUDFRONT_DISTRIBUTION_ID')
    origin_id = os.environ.get('CLOUDFRONT_ORIGIN_ID')
    autorizer_header = os.environ.get('CLOUDFRONT_AUTHORIZER_HEADER_NAME')

    # Rotate SSM parameter and get new value
    result = rotate_ssm_parameter(parameter_name)
    new_value = result['new_value']

    # Update CloudFront origin header
    update_cloudfront_origin_header(distribution_id, origin_id , autorizer_header, new_value)

    return result
