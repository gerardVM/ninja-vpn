package main

import (
	"fmt"
	"log"
	"encoding/json"
    "github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-lambda-go/events"
    "github.com/aws/aws-sdk-go/aws/session"
	lambda "github.com/aws/aws-lambda-go/lambda"
    lambda_trigger "github.com/aws/aws-sdk-go/service/lambda"
)

func HandleRequest(request events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
// func HandleRequest(request events.APIGatewayProxyRequest) error {

	// Assuming the request body contains JSON data
    // var requestBody map[string]string
    // err := json.Unmarshal([]byte(request.Body), &requestBody)
    // if err != nil {
    //     return events.APIGatewayProxyResponse{}, fmt.Errorf("failed to unmarshal request body: %v", err)
    // }

	// Extract parameters
	// action 		 := requestBody["action"]
	// email 		 := requestBody["email"]
	// timezone 	 := requestBody["timezone"]
	// countdown 	 := requestBody["countdown"]
	// region 		 := requestBody["region"]

	action := "deploy"
	email := "valverdegerard@gmail.com"
	timezone := "Europe/Paris"
	countdown := "10 minutes"
	region := "eu-west-2"

	// Prepare your response
	headers := map[string]string{
		"Content-Type": "application/json",
		"Access-Control-Allow-Origin": "*", // Add necessary CORS headers
	}

	body := map[string]interface{}{
		"message": "You have requested to " + action + " a VPN for " + email + " in " + region + " with a countdown of " + countdown + " minutes to be ready at " + timezone,
	}

	// Marshal the response into JSON
	responseBody, err := json.Marshal(body)
	if err != nil {
		return events.APIGatewayProxyResponse{}, fmt.Errorf("failed to marshal response body: %v", err)
	}

	// Call lambda function
	sess, err := session.NewSession(&aws.Config{
		Region: aws.String("eu-west-3")},
	)
	if err != nil {
		log.Fatalf("failed to create session: %v", err)
	}

	svc := lambda_trigger.New(sess)

	input := &lambda_trigger.InvokeInput{
		FunctionName: aws.String("vpn-controller"),
		Payload:      []byte("{\"action\":\"" + action + "\",\"email\":\"" + email + "\",\"timezone\":\"" + timezone + "\",\"countdown\":\"" + countdown + "\",\"region\":\"" + region + "\"}"),
	}	

	fmt.Println("flag6")

	result, err := svc.Invoke(input)
	if err != nil {
		log.Fatalf("failed to invoke function: %v", err)
	}

	fmt.Println("flag7")

	fmt.Println(string(result.Payload))

	fmt.Println("flag8")

	// Unmarshal the response into JSON
	return events.APIGatewayProxyResponse{
		StatusCode: 200,
		Headers:    headers,
		Body:       string(responseBody),
	}, nil
}

func main() {
	lambda.Start(HandleRequest)
}