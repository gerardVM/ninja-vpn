package main

import (
	"os"
	"fmt"
	"log"	
	"encoding/json"
	"context"
	"strings"
	"io/ioutil"
	"path/filepath"
	"go.mozilla.org/sops/decrypt"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/go-yaml/yaml"
	"github.com/go-git/go-git/v5"
	"github.com/hashicorp/go-version"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/ses"
	"github.com/hashicorp/hc-install/product"
	"github.com/hashicorp/hc-install/releases"
	"github.com/hashicorp/terraform-exec/tfexec"
)

type VPNConfig struct {
	Action    	  string 		 `yaml:"action"`
	Email     	  string 		 `yaml:"email"`
	Timezone  	  string 		 `yaml:"timezone"`
	Countdown 	  string 		 `yaml:"countdown"`
	Region    	  string 		 `yaml:"region"`
}

func decryptConfigFile(inputFilePath string, outputFilePath string) error {
    // Use the decrypt package to decrypt the file. The first argument is a byte array
    cleartext, err := decrypt.File(inputFilePath, "yaml")
    if err != nil {
        return err
    }

    fmt.Println("File decrypted successfully.")

	// Write the cleartext to a file
	err = ioutil.WriteFile(outputFilePath, cleartext, 0644)
	if err != nil {
		return err
	}

	fmt.Println("File written successfully.")

	return nil
}

func updateConfigFile(destination string, action string, email string, timezone string, countdown string, region string) error {
	config_append := VPNConfig{
		Action:    action,
		Email:     email,
		Timezone:  timezone,
		Countdown: countdown,
		Region:    region,
	}

	yamlData, err := yaml.Marshal(config_append)
	if err != nil {
		return err
	}

	filename := filepath.Join(destination, "config.yaml")

	// Open the file in append mode
	file, err := os.OpenFile(filename, os.O_APPEND|os.O_WRONLY, 0644)
	if err != nil {
		return err
	}
	defer file.Close()

	// Append yamlData to the file
	_, err = file.Write(yamlData)
	if err != nil {
		return err
	}

	return nil
}

func cloneRepository(repoURL, destination string) error {
	_, err := git.PlainClone(destination, false, &git.CloneOptions{
		URL:      repoURL,
		Progress: os.Stdout,
	})
	return err
}

func sendTerminationEmail(ctx context.Context, senderEmail, sesRegion, region, receiverEmail string) (string, error) {
	destination := &ses.Destination{
		ToAddresses: []*string{aws.String(receiverEmail)},
	}

	message := &ses.Message{
		Subject: &ses.Content{
			Data: aws.String("VPN server terminated"),
		},
		Body: &ses.Body{
			Text: &ses.Content{
				Data: aws.String(fmt.Sprintf("The VPN server in region %s has been terminated for %s.", region, receiverEmail)),
			},
		},
	}

	sess, err := session.NewSession(&aws.Config{
		Region: aws.String(sesRegion),
	})
	if err != nil {
		return "", err
	}

	sesClient := ses.New(sess)
	_, err = sesClient.SendEmailWithContext(ctx, &ses.SendEmailInput{
		Destination: destination,
		Message:     message,
		Source:      aws.String(senderEmail),
	})
	if err != nil {
		return "", err
	}

	return "Success", nil
}

func launchTerraform(directory string, action string, email string, region string) error {
	installer := &releases.ExactVersion{
		Product: product.Terraform,
		Version: version.Must(version.NewVersion("1.4.4")),
	}

	execPath, err := installer.Install(context.Background())
	if err != nil {
		log.Fatalf("error installing Terraform: %s", err)
	}	

	tf, err := tfexec.NewTerraform(directory, execPath)
	if err != nil {
		log.Fatalf("error running NewTerraform: %s", err)
	}

	backendConfig := tfexec.BackendConfig(fmt.Sprintf("key=%s/%s/terraform.tfstate", strings.Split(email,"@")[0], region))

	err = tf.Init(context.Background(), tfexec.Upgrade(true), backendConfig)
	if err != nil {
		log.Fatalf("error running Init: %s", err)
	}

	// Apply or Destroy

	switch action {

		case "deploy":
			_, err = tf.Plan(context.Background(), tfexec.Out(filepath.Join(directory,"plan.out")))
			if err != nil {
				log.Fatalf("error running Plan: %s", err)
			}

			err = tf.Apply(context.Background())
			if err != nil {
				log.Fatalf("error running Apply: %s", err)
			}

			fmt.Println("VPN deployed! You will receive an email with your VPN configuration after 2 minutes")

		case "destroy":
			senderEmail := os.Getenv("SENDER_EMAIL")
			sesRegion := os.Getenv("SES_REGION")

			_, err = sendTerminationEmail(context.Background(), senderEmail, sesRegion, region, email)
			if err != nil {
				log.Fatalf("error sending email: %s", err)
			}

			err = tf.Destroy(context.Background())
			if err != nil {
				log.Fatalf("error running Destroy: %s", err)
			}

			fmt.Println("Destroy completed")

		default:
			fmt.Println("Action can only be deploy or destroy")
	}

	return nil
}

func HandleRequest(ctx context.Context, event json.RawMessage) error {

	// Extract parameters
	var inputData map[string]string
	err := json.Unmarshal([]byte(event), &inputData)
	if err != nil {
		return fmt.Errorf("failed to unmarshal request body: %v", err)
	}

	// Extract parameters
	action 		 := inputData["ACTION"]
	email 		 := inputData["EMAIL"]
	timezone 	 := inputData["TIMEZONE"]
	countdown 	 := inputData["COUNTDOWN"]
	region 		 := inputData["REGION"]

	// Replace `repoURL` with the actual repository URL
	repoURL := "https://github.com/gerardVM/ninja-vpn"

	// Create a temporary directory
	tempDir, err := ioutil.TempDir("", "temp-clone")
	if err != nil {
		return fmt.Errorf("failed to create temp directory: %v", err)
	}
	defer os.RemoveAll(tempDir)

	// Clone the repository
	err = cloneRepository(repoURL, tempDir)
	if err != nil {
		return fmt.Errorf("failed to clone repository: %v", err)
	}

	// Unencrypt the config.enc.yaml file
	err = decryptConfigFile(filepath.Join(tempDir,"config.enc.yaml"), filepath.Join(tempDir, "config.yaml"))
	if err != nil {
		fmt.Println(err)
	}

	// Update the file config.yaml file
	err = updateConfigFile(tempDir, action, email, timezone, countdown, region)
	if err != nil {
		return fmt.Errorf("failed to create config.yaml file: %v", err)
	}

	terraformDir := filepath.Join(tempDir, "ops/terraform/aws/vpn")

	// Launch Terraform
	err = launchTerraform(terraformDir, action, email, region)
	if err != nil {
		return fmt.Errorf("failed to launch Terraform: %v", err)
	}

	fmt.Println("Done! Parameters: ", action, email, timezone, countdown, region)

	return nil
}

func main() {
	lambda.Start(HandleRequest)
}