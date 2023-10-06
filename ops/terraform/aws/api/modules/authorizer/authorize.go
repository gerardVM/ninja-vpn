package main

import (
	"context"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
)

func handler(ctx context.Context, request events.APIGatewayV2CustomAuthorizerV1Request) (events.APIGatewayCustomAuthorizerResponse, error) {
	headers := request.Headers
	originVerifyHeader := headers["x-origin-verify"]

	if originVerifyHeader == "valid-token" {
		return generatePolicy("testing_the_lambda_authorizer", "Allow", request.MethodArn), nil
	}

	return generatePolicy("testing_the_lambda_authorizer", "Deny", request.MethodArn), nil
}

func generatePolicy(principalID, effect, resource string) events.APIGatewayCustomAuthorizerResponse {
	policy := events.APIGatewayCustomAuthorizerResponse{
		PrincipalID: principalID,
		PolicyDocument: events.APIGatewayCustomAuthorizerPolicy{
			Version: "2012-10-17",
			Statement: []events.IAMPolicyStatement{
				{
					Action:   []string{"execute-api:Invoke"},
					Effect:   effect,
					Resource: []string{resource},
				},
			},
		},
	}

	return policy
}

func main() {
	lambda.Start(handler)
}
