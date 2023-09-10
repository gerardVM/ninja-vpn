package main

import (
	"context"
	"fmt"
	"log"
	"io/ioutil"
	"os"
	"strings"
	"path/filepath"
    "github.com/go-git/go-git/v5"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/go-yaml/yaml"
	"github.com/hashicorp/go-version"
	"github.com/hashicorp/hc-install/product"
	"github.com/hashicorp/hc-install/releases"
	"github.com/hashicorp/terraform-exec/tfexec"
)

type VPNConfig struct {
	Name          string 		 `yaml:"name"`
	Image         string 		 `yaml:"image"`
	InstanceType  string 		 `yaml:"instance_type"`
	ExistingData  ExistingData   `yaml:"existing_data"`
	Action    	  string 		 `yaml:"action"`
	Email     	  string 		 `yaml:"email"`
	Timezone  	  string 		 `yaml:"timezone"`
	Countdown 	  string 		 `yaml:"countdown"`
	Region    	  string 		 `yaml:"region"`
}

type ExistingData struct {
	Region    	  string 		 `yaml:"region"`
	Bucket    	  string 		 `yaml:"bucket"`
	SESSender 	  string 		 `yaml:"ses_sender"`
}

func createConfigFile(destination string, sender_email string, action string, email string, timezone string, countdown string, region string) error {
	config := VPNConfig{
		Name:         "ninja-vpn",
		Image:        "al2023-ami-2023",
		InstanceType: "t2.micro",
		ExistingData: ExistingData{
			Region:    "eu-west-3",
			Bucket:    "ninja-vpn-resources",
			SESSender: sender_email,
		},
		Action:    action,
		Email:     email,
		Timezone:  timezone,
		Countdown: countdown,
		Region:    region,
	}

	yamlData, err := yaml.Marshal(config)
	if err != nil {
		return err
	}

	filename := filepath.Join(destination, "config.yaml")
	err = ioutil.WriteFile(filename, yamlData, 0644)
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

func editResourcesFile(template string, destination string, region string, user string) error {
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

func launchTerraform(directory string) error {
	installer := &releases.ExactVersion{
		Product: product.Terraform,
		Version: version.Must(version.NewVersion("1.4.4")),
	}

	execPath, err := installer.Install(context.Background())
	if err != nil {
		log.Fatalf("error installing Terraform: %s", err)
	}	

	workingDir := filepath.Join(directory, "ops/terraform/aws/")
	tf, err := tfexec.NewTerraform(workingDir, execPath)
	if err != nil {
		log.Fatalf("error running NewTerraform: %s", err)
	}

	err = tf.Init(context.Background(), tfexec.Upgrade(true))
	if err != nil {
		log.Fatalf("error running Init: %s", err)
	}

	// Apply or Destroy

	switch os.Getenv("ACTION") {

		case "deploy":
			_, err = tf.Plan(context.Background(), tfexec.Out(filepath.Join(workingDir,"plan.out")))
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


func HandleRequest(ctx context.Context) error {
	// Replace `repoURL` with the actual repository URL
	repoURL := "https://github.com/gerardVM/ninja-vpn"

	// Create a temporary directory
	tempDir, err := ioutil.TempDir("", "temp-clone")
	if err != nil {
		return fmt.Errorf("failed to create temp directory: %v", err)
	}
	defer os.RemoveAll(tempDir)
	// fmt.Println("tempDir: ", tempDir)

	// Clone the repository
	err = cloneRepository(repoURL, tempDir)
	if err != nil {
		return fmt.Errorf("failed to clone repository: %v", err)
	}

	// Create the file config.yaml from $SENDER_EMAIL enrivonment vraiable
	err = createConfigFile(tempDir, os.Getenv("SENDER_EMAIL"), os.Getenv("ACTION"), os.Getenv("EMAIL"), os.Getenv("TIMEZONE"), os.Getenv("COUNTDOWN"), os.Getenv("REGION")) 
	if err != nil {
		return fmt.Errorf("failed to create config.yaml file: %v", err)
	}

	// Edit the file resources.tf
	err = editResourcesFile(filepath.Join(tempDir, "ops/terraform/aws/templates/00-resources.tpl"), filepath.Join(tempDir, "ops/terraform/aws/00-resources.tf"), os.Getenv("REGION"), strings.Split(os.Getenv("EMAIL"),"@")[0]) // Remember to update the path
	if err != nil {
		return fmt.Errorf("failed to edit resources.tf file: %v", err)
	}

	err = os.Chmod(filepath.Join(tempDir, "ops/terraform/aws/00-resources.tf"), 0644)
	if err != nil {
		return fmt.Errorf("failed to change permissions of resources.tf file: %v", err)
	}

	// Launch Terraform
	err = launchTerraform(tempDir)
	if err != nil {
		return fmt.Errorf("failed to launch Terraform: %v", err)
	}

	return nil
}

func main() {
	lambda.Start(HandleRequest)
}