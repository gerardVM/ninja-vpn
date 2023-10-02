# BACKEND

This project use Golang as the main language for the backend. The backend is responsible for the following tasks:
- Receive the request from the API Gateway, validate it, send it to the VPN launcher and return the response to the API Gateway.
- Receive the validated request and launch the VPN service by applying the `./ops/terraform/aws/vpn` Terraform code.

All backend is deployed in AWS Lambda functions.
