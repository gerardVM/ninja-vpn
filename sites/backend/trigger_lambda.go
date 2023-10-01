package main

import (
	"os"
	"fmt"
	"log"
	"time"
	"encoding/json"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-sdk-go/aws/session"
	lambda "github.com/aws/aws-lambda-go/lambda"
    lambda_trigger "github.com/aws/aws-sdk-go/service/lambda"
)

func invokeLambda(action, email, timezone, countdown, region string) error {
	lambda_region := os.Getenv("API_REGION")

	sess, err := session.NewSession(&aws.Config{
		Region: aws.String(lambda_region)},
	)
	if err != nil {
		log.Fatalf("failed to create session: %v", err)
	}

	svc := lambda_trigger.New(sess)

	fmt.Println("Action: ", action, ", Email: ", email, ", Timezone: ", timezone, ", Countdown: ", countdown, ", Region: ", region)

	input := &lambda_trigger.InvokeInput{
		FunctionName: aws.String("ninja-vpn-controller"),
		Payload:      []byte("{\"ACTION\":\"" + action + "\",\"EMAIL\":\"" + email + "\",\"TIMEZONE\":\"" + timezone + "\",\"COUNTDOWN\":\"" + countdown + "\",\"REGION\":\"" + region + "\"}"),
	}

	_, err = svc.Invoke(input)
	if err != nil {
		log.Fatalf("failed to invoke function: %v", err)
	}

	return nil
}


func HandleRequest(request events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {

	// Assuming the request body contains JSON data
	var requestBody map[string]string
	err := json.Unmarshal([]byte(request.Body), &requestBody)
	if err != nil {
		return events.APIGatewayProxyResponse{}, fmt.Errorf("failed to unmarshal request body: %v", err)
	}

	// Extract parameters
	action 		 := requestBody["action"]
	email 		 := requestBody["email"]
	timezone 	 := requestBody["timezone"]
	countdown 	 := requestBody["countdown"]
	region 		 := requestBody["region"]

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
	go invokeLambda(action, email, timezone, countdown, region)

	// Sleep for 1 second
	time.Sleep(time.Second)

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