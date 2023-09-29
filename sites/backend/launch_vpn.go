package main

import (
	"os"
	"fmt"
	"log"
	"context"
	"strings"
	"io/ioutil"
	"encoding/json"
	"path/filepath"
	"go.mozilla.org/sops/decrypt"
	"github.com/go-yaml/yaml"
	"github.com/go-git/go-git/v5"
	"github.com/hashicorp/go-version"
	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
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

func editPreferencesFile(template string, destination string, region string, user string) error {
	// Read the file
	data, err := ioutil.ReadFile(template)
	if err != nil {
		return err
	}

	// Replace the region
	newContents := strings.Replace(string(data), "<REGION>", region, -1)

	// Replace the user
	newContents = strings.Replace(newContents, "<USER>", user, -1)

	// Write the file
	err = ioutil.WriteFile(destination, []byte(newContents), 0)
	if err != nil {
		return err
	}

	return nil
}

func launchTerraform(directory string, action string) error {
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

	err = tf.Init(context.Background(), tfexec.Upgrade(true))
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

func HandleRequest(request events.APIGatewayProxyRequest) (response events.APIGatewayProxyResponse, err error) {

	// Assuming the request body contains JSON data
    var requestBody map[string]string
    err := json.Unmarshal([]byte(request.Body), &requestBody)
    if err != nil {
        return fmt.Errorf("failed to unmarshal request body: %v", err)
    }

	// Prepare your response
	headers := map[string]string{
		"Content-Type": "application/json",
		"Access-Control-Allow-Origin": "*", // Add necessary CORS headers
	}

	body := map[string]interface{}{
		"message": "Hello from Go Lambda!",
		"path":    path, // Include the path in the response if needed
	}

	// Marshal the response into JSON
	responseBody, err := json.Marshal(body)
	if err != nil {
		return fmt.Errorf("failed to marshal response body: %v", err)
	}

    // // Extract parameters
    // action 		 := requestBody["action"]
    // email 		 := requestBody["email"]
    // timezone 	 := requestBody["timezone"]
    // countdown 	 := requestBody["countdown"]
    // region 		 := requestBody["region"]

	// // Replace `repoURL` with the actual repository URL
	// repoURL := "https://github.com/gerardVM/ninja-vpn"

	// // Create a temporary directory
	// tempDir, err := ioutil.TempDir("", "temp-clone")
	// if err != nil {
	// 	return fmt.Errorf("failed to create temp directory: %v", err)
	// }
	// defer os.RemoveAll(tempDir)

	// // Clone the repository
	// err = cloneRepository(repoURL, tempDir)
	// if err != nil {
	// 	return fmt.Errorf("failed to clone repository: %v", err)
	// }

	// // Unencrypt the config.enc.yaml file
	// err = decryptConfigFile(filepath.Join(tempDir,"config.enc.yaml"), filepath.Join(tempDir, "config.yaml"))
	// if err != nil {
	// 	fmt.Println(err)
	// }

	// // Update the file config.yaml file
	// err = updateConfigFile(tempDir, action, email, timezone, countdown, region)
	// if err != nil {
	// 	return fmt.Errorf("failed to create config.yaml file: %v", err)
	// }

	// terraformDir := filepath.Join(tempDir, "ops/terraform/aws/vpn")

	// // Edit the file preferences.tf
	// err = editPreferencesFile(filepath.Join(terraformDir, "templates/00-preferences.tpl"), filepath.Join(terraformDir, "00-preferences.tf"), region, strings.Split(email,"@")[0]) // Remember to update the path
	// if err != nil {
	// 	return fmt.Errorf("failed to edit preferences.tf file: %v", err)
	// }

	// err = os.Chmod(filepath.Join(terraformDir, "00-preferences.tf"), 0644)
	// if err != nil {
	// 	return fmt.Errorf("failed to change permissions of preferences.tf file: %v", err)
	// }

	// // Launch Terraform
	// err = launchTerraform(terraformDir, action)
	// if err != nil {
	// 	return fmt.Errorf("failed to launch Terraform: %v", err)
	// }

	// fmt.Println("Done! Parameters: ", action, email, timezone, countdown, region)

	return events.APIGatewayProxyResponse{
		StatusCode: 200,
		Headers:    headers,
		Body:       string(responseBody),
	}, nil
}

func main() {
	lambda.Start(HandleRequest)
}