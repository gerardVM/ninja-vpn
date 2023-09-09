package main

import (
	"context"
	"fmt"
	"io/ioutil"
	"os"
	"strings"
	"path/filepath"
    "github.com/go-git/go-git/v5"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/go-yaml/yaml"
)

// type MyEvent struct {
// 	Name string `json:"name"`
// }

type VPNConfig struct {
	Name          string 		 `yaml:"name"`
	Image         string 		 `yaml:"image"`
	InstanceType  string 		 `yaml:"instance_type"`
	ExistingData  ExistingData   `yaml:"existing_data"`
}

type ExistingData struct {
	Region    string `yaml:"region"`
	Bucket    string `yaml:"bucket"`
	SESSender string `yaml:"ses_sender"`
}

type User struct {
	Action    string `yaml:"action"`
	Email     string `yaml:"email"`
	Timezone  string `yaml:"timezone"`
	Countdown string `yaml:"countdown"`
	Region    string `yaml:"region"`
}

func createCommonFile(destination string, email string) error {
	config := VPNConfig{
		Name:         "ninja-vpn",
		Image:        "al2023-ami-2023",
		InstanceType: "t2.micro",
		ExistingData: ExistingData{
			Region:    "eu-west-3",
			Bucket:    "ninja-vpn-resources",
			SESSender: email,
		},
	}

	yamlData, err := yaml.Marshal(config)
	if err != nil {
		return err
	}

	// filename := fmt.Sprintf("%s%s.yaml", destination, "common")
	filename := filepath.Join(destination, "common.yaml")
	err = ioutil.WriteFile(filename, yamlData, 0644)
	if err != nil {
		return err
	}

	return nil
}

func createUserFile(destination string, action string, email string, timezone string, countdown string, region string) error {
	user := User{
		Action:    action,
		Email:     email,
		Timezone:  timezone,
		Countdown: countdown,
		Region:    region,
	}

	yamlData, err := yaml.Marshal(user)
	if err != nil {
		return err
	}

	// filename := fmt.Sprintf("%s%s.yaml", destination, strings.Split(email, "@"))
	filename := filepath.Join(destination, strings.Split(email, "@")[0]+".yaml")
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

func HandleRequest(ctx context.Context) error {
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

	// Create the file common.yaml from $SENDER_EMAIL enrivonment vraiable
	err = createCommonFile(tempDir, os.Getenv("SENDER_EMAIL")) 
	if err != nil {
		return fmt.Errorf("failed to create common.yaml file: %v", err)
	}

	// Create the user.yaml file from the request body
	err = createUserFile(filepath.Join(tempDir,"users"), os.Getenv("ACTION"), os.Getenv("EMAIL"), os.Getenv("TIMEZONE"), os.Getenv("COUNTDOWN"), os.Getenv("REGION"))
	if err != nil {
		return fmt.Errorf("failed to create user.yaml file: %v", err)
	}

	// Read the Common file
	commonContent, err := ioutil.ReadFile(filepath.Join(tempDir, "common.yaml"))
	if err != nil {
		return fmt.Errorf("failed to read common.yaml: %v", err)
	}

	// Display the Common content (you can modify this part as per your requirements)
	fmt.Printf("Common Content:\n%s\n", string(commonContent))

	// Read the user file
	userContent, err := ioutil.ReadFile(filepath.Join(tempDir, filepath.Join("users", strings.Split(os.Getenv("EMAIL"), "@")[0]))+".yaml")
	if err != nil {
		return fmt.Errorf("failed to read user.yaml: %v", err)
	}

	// Display the user content (you can modify this part as per your requirements)
	fmt.Printf("User Content:\n%s\n", string(userContent))

	return nil
}

func main() {
	lambda.Start(HandleRequest)
}
