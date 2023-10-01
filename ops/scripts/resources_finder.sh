

case $1 in
    --region)
        regions=$2
        ;;
    *)
        regions=$(aws ec2 describe-regions --output text --query 'Regions[*].RegionName')
        ;;
esac

echo "Roles and policies"
ninja_roles=$(aws iam list-roles --output text --query 'Roles[*].[RoleName,Arn,Description]' | grep -i ninja)
ninja_policies=$(aws iam list-policies --output text --query 'Policies[*].[PolicyName,Arn,Description]' | grep -i ninja)
echo "$ninja_roles"
echo "$ninja_policies"

echo "------------------------"

# Loop through each region
for region in $regions
do
    echo "Region: $region"
    
    # Set the region for the AWS CLI
    export AWS_DEFAULT_REGION=$region
    
    # Get the list of Elastic IPs in the region
    elastic_ips=$(aws ec2 describe-addresses --output text --query 'Addresses[*].[PublicIp,InstanceId,AllocationId,Domain]')
    ec2_instances=$(aws ec2 describe-instances --output text --query 'Reservations[*].Instances[*].[InstanceId,InstanceType,State.Name,Tags[?Key==`Name`].Value | [0]]')
    lambda_functions=$(aws lambda list-functions --output text --query 'Functions[*].[FunctionName,Runtime,Handler,Role,Description]')
    
    # Print the list of Elastic IPs
    echo "$elastic_ips"
    echo "$ec2_instances"
    echo "$lambda_functions"
    
    echo "------------------------"
done