# NINJA VPN

The NINJA VPN is a WireGuard-based VPN service that is launched in AWS spot EC2 instances in a location of your choice for a limited amount of time. It sends you an email with the configuration file so you just need to download it and use it in your WireGuard client.

# NINJA VPN API

The NINJA VPN API refers to all the resources that are needed so the user is able to launch the NINJA VPN service in a simple and easy way. The API is built using following serverless AWS resources: API Gateway, Lambda, S3, Step Functions and CloudFront.