package main

import (
	"context"
	"fmt"
	"os"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/ssm"
)

func read_ssm_parameter(parameter_name string) (string, error) {
    svc := ssm.New(session.New())
    param, err := svc.GetParameter(&ssm.GetParameterInput{
        Name:           aws.String(parameter_name),
		WithDecryption: aws.Bool(true),
    })
    if err != nil {
        return "", err
    }
    return *param.Parameter.Value, nil
}

func get_previous_ssm_parameter_version(parameter_name string) (string, error) {
    svc := ssm.New(session.New())

    // Get parameter history
    history, err := svc.GetParameterHistory(&ssm.GetParameterHistoryInput{
        Name: aws.String(parameter_name),
		WithDecryption: aws.Bool(true),
    })

    if err != nil {
        return "", err
    }

    // Check if there's a previous version
    if len(history.Parameters) < 2 {
        return "", fmt.Errorf("No previous version found for %s", parameter_name)
    }

    // The last item in the list is the latest version, so we'll take the second to last
    prevVersion := history.Parameters[len(history.Parameters)-2]

    // Get the value of the previous version
    prevValue := *prevVersion.Value

    return prevValue, nil
}

func handler(ctx context.Context, request events.APIGatewayV2CustomAuthorizerV2Request) (events.APIGatewayCustomAuthorizerResponse, error) {
	headers := request.Headers
	originVerifyHeader := headers["x-origin-verify"]

	last_version_ssm_parameter, err := read_ssm_parameter(os.Getenv("SSM_SECRET_NAME"))
	if err != nil {
		fmt.Println("Error: ", err)
	}

	second_to_last_version_ssm_parameter, err := get_previous_ssm_parameter_version(os.Getenv("SSM_SECRET_NAME"))
	if err != nil {
		fmt.Println("Error: ", err)
	}

	if originVerifyHeader != last_version_ssm_parameter && originVerifyHeader != second_to_last_version_ssm_parameter {
		return generatePolicy("lambda_authorizer_deny", "Deny", request.RouteArn), nil
	}

	return generatePolicy("lambda_authorizer_allow", "Allow", request.RouteArn), nil
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
