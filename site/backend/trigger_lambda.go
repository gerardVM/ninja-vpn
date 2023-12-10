package main

import (
	"os"
	"fmt"
	"log"
	"time"
	"errors"
	"regexp"
	"strings"
	"encoding/json"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/dynamodb"
	lambda "github.com/aws/aws-lambda-go/lambda"
    lambda_trigger "github.com/aws/aws-sdk-go/service/lambda"
)

func isValidEmail(email string) bool {
	// Use a regular expression to validate the email format
	regex := `^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`
	return regexp.MustCompile(regex).MatchString(email)
}

func sanitizeInput(email string) string {
	return strings.TrimSpace(strings.ToLower(email))
}

func checkIfEmailExists(email string) (bool, error) {
	// Validate email
	if !isValidEmail(email) {
		return false, errors.New("Invalid email address format")
	}

	// Sanitize email
	email = sanitizeInput(email)

	dynamodbRegion := os.Getenv("API_REGION")

	// Initialize a session using the environment's AWS credentials
	sess := session.Must(session.NewSession(&aws.Config{
		Region: aws.String(dynamodbRegion),
	}))

	// Create a DynamoDB client
	svc := dynamodb.New(sess)

	// Define the input parameters for the query
	input := &dynamodb.GetItemInput{
		TableName: aws.String(os.Getenv("DYNAMODB_TABLE")),
		Key: map[string]*dynamodb.AttributeValue{
			"email": {
				S: aws.String(email),
			},
		},
	}

	// Make the query to DynamoDB
	result, err := svc.GetItem(input)
	if err != nil {
		log.Println("Error querying DynamoDB:", err)
		return false, err
	}

	// Check if the item was found
	if result.Item == nil {
		return false, nil
	}

	return true, nil
}


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
	action 		 := os.Getenv("ACTION")
	email 		 := requestBody["email"]
	timezone 	 := requestBody["timezone"]
	countdown 	 := requestBody["countdown"]
	region 		 := requestBody["region"]

	// Prepare your response
	headers := map[string]string{
		"Content-Type": "application/json",
		"Access-Control-Allow-Origin": "*", // Add necessary CORS headers
	}

	success_body := map[string]interface{}{
		"message": "Success! You have requested to " + action + " a VPN for " + email + " in " + region + " for " + countdown,
	}

	// Marshal the response into JSON
	successResponseBody, err := json.Marshal(success_body)
	if err != nil {
		return events.APIGatewayProxyResponse{}, fmt.Errorf("failed to marshal response body: %v", err)
	}

	deny_body := map[string]interface{}{
		"message": "Error! " + email + " is not authorized to use this service",
	}

	// Marshal the response into JSON
	denyResponseBody, err := json.Marshal(deny_body)
	if err != nil {
		return events.APIGatewayProxyResponse{}, fmt.Errorf("failed to marshal response body: %v", err)
	}

	emailExistsInDB, err := checkIfEmailExists(email)
	if err != nil {
		fmt.Println("Error: ", err)
	}

	if !emailExistsInDB {
		return events.APIGatewayProxyResponse{
			StatusCode: 400,
			Headers:    headers,
			Body:       string(denyResponseBody),
		}, nil
	}

	// Call lambda function
	go invokeLambda(action, email, timezone, countdown, region)

	// Sleep for 1 second
	time.Sleep(time.Second)

	// Unmarshal the response into JSON
	return events.APIGatewayProxyResponse{
		StatusCode: 200,
		Headers:    headers,
		Body:       string(successResponseBody),
	}, nil
}

func main() {
	lambda.Start(HandleRequest)
}