regions=$(aws ec2 describe-regions --output text --query 'Regions[*].RegionName')

# Loop through each region
# for region in $regions
# do
    region="us-east-1"
    echo "Region: $region"
    
    # Set the region for the AWS CLI
    export AWS_DEFAULT_REGION=$region
    
    # Get the list of Elastic IPs in the region
    elastic_ips=$(aws ec2 describe-addresses --output text --query 'Addresses[*].[PublicIp,InstanceId,AllocationId,Domain]')
    ec2_instances=$(aws ec2 describe-instances --output text --query 'Reservations[*].Instances[*].[InstanceId,InstanceType,State.Name,Tags[?Key==`Name`].Value | [0]]')
    lambda_functions=$(aws lambda list-functions --output text --query 'Functions[*].[FunctionName,Runtime,Handler,Role,Description]')
    ninja_roles=$(aws iam list-roles --output text --query 'Roles[*].[RoleName,Arn,Description]' | grep -i ninja)
    ninja_policies=$(aws iam list-policies --output text --query 'Policies[*].[PolicyName,Arn,Description]' | grep -i ninja)
    
    # Print the list of Elastic IPs
    echo "$elastic_ips"
    echo "$ec2_instances"
    echo "$lambda_functions"
    echo "$ninja_roles"
    echo "$ninja_policies"
    
    echo "------------------------"
# done