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
	// "github.com/aws/aws-lambda-go/lambda"
	"github.com/go-yaml/yaml"
	"github.com/hashicorp/go-version"
	"github.com/hashicorp/hc-install/product"
	"github.com/hashicorp/hc-install/releases"
	"github.com/hashicorp/terraform-exec/tfexec"
)

// type MyEvent struct {
// 	Name string `json:"name"`
// }

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
	Region    string `yaml:"region"`
	Bucket    string `yaml:"bucket"`
	SESSender string `yaml:"ses_sender"`
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

func HandleRequest(ctx context.Context) error {
	// Replace `repoURL` with the actual repository URL
	repoURL := "https://github.com/gerardVM/ninja-vpn"

	// Create a temporary directory
	tempDir, err := ioutil.TempDir("", "temp-clone")
	if err != nil {
		return fmt.Errorf("failed to create temp directory: %v", err)
	}
	// defer os.RemoveAll(tempDir)
	fmt.Println("tempDir: ", tempDir)

	// Clone the repository
	err = cloneRepository(repoURL, tempDir)
	if err != nil {
		return fmt.Errorf("failed to clone repository: %v", err)
	}

	// to delete
	// content, err := ioutil.ReadFile(filepath.Join(tempDir, "README.md"))
	// if err != nil {
	// 	return fmt.Errorf("failed to read config.yaml file: %v", err)
	// }
	// fmt.Println("hello")

	// Create the file config.yaml from $SENDER_EMAIL enrivonment vraiable
	err = createConfigFile(tempDir, os.Getenv("SENDER_EMAIL"), os.Getenv("ACTION"), os.Getenv("EMAIL"), os.Getenv("TIMEZONE"), os.Getenv("COUNTDOWN"), os.Getenv("REGION")) 
	if err != nil {
		return fmt.Errorf("failed to create config.yaml file: %v", err)
	}

	// to delete
	// content, err := ioutil.ReadFile(filepath.Join(tempDir, "config.yaml"))
	// content, err := ioutil.ReadFile(filepath.Join(tempDir, "ops/terraform/aws/templates/00-resources.tpl"))
	// if err != nil {
	// 	return fmt.Errorf("failed to read config.yaml file: %v", err)
	// }
	// fmt.Println(string(content))

	// Edit the file resources.tf
	err = editResourcesFile(filepath.Join(tempDir, "ops/terraform/aws/templates/00-resources.tpl"), filepath.Join(tempDir, "ops/terraform/aws/00-resources.tf"), os.Getenv("REGION"), strings.Split(os.Getenv("EMAIL"),"@")[0]) // Remember to update the path
	if err != nil {
		return fmt.Errorf("failed to edit resources.tf file: %v", err)
	}

	err = os.Chmod(filepath.Join(tempDir, "ops/terraform/aws/00-resources.tf"), 0644)
	if err != nil {
		return fmt.Errorf("failed to change permissions of resources.tf file: %v", err)
	}

	// to delete
	content, err := ioutil.ReadFile(filepath.Join(tempDir, "ops/terraform/aws/00-resources.tf"))
	if err != nil {
		log.Fatalf("error reading file: %s", err)
		return fmt.Errorf("failed to read 00-resources file: %v", err)
	}
	fmt.Println(string(content))

	// Set up Terraform	
	installer := &releases.ExactVersion{
		Product: product.Terraform,
		Version: version.Must(version.NewVersion("1.4.4")),
	}

	execPath, err := installer.Install(context.Background())
	if err != nil {
		log.Fatalf("error installing Terraform: %s", err)
	}	

	workingDir := filepath.Join(tempDir, "ops/terraform/aws")
	tf, err := tfexec.NewTerraform(workingDir, execPath)
	if err != nil {
		log.Fatalf("error running NewTerraform: %s", err)
	}

	fmt.Println(tf)
	fmt.Println(workingDir)

	// readDir, err := tf.workingDir()

	// fmt.Println(tf)
	// fmt.Println(readDir)

	// err = os.Chdir(tempDir)
	// if err != nil {
	// 	log.Fatalf("error running Chdir: %s", err)
	// }

	err = tf.Init(context.Background(), tfexec.Upgrade(true))
	if err != nil {
		log.Fatalf("error running Init: %s", err)
	}

	version, _, err := tf.Version(context.Background(), true)
	if err != nil {
		log.Fatalf("error running Version: %s", err)
	}

	theDir := tf.WorkingDir()

	fmt.Println(version)
	fmt.Println(theDir)

	// state, err := tf.Show(context.Background())
	// if err != nil {
	// 	log.Fatalf("error running Show: %s", err)
	// }

	plan, err := tf.Plan(context.Background(), tfexec.Out(workingDir))
	if err != nil {
		log.Fatalf("error running Plan: %s", err)
	}

	

	// fmt.Println(state.FormatVersion)
	fmt.Println(plan)
	// fmt.Println(state.Modules[0].Resources["aws_instance.ninja-vpn"].Primary.Attributes["public_ip"])

	return nil
}

func main() {
	// lambda.Start(HandleRequest)
	os.Setenv("SENDER_EMAIL", "valverdegerard+sender@gmail.com")
	os.Setenv("EMAIL", "valverdegerard@gmail.com")
	os.Setenv("ACTION", "deploy")
	os.Setenv("TIMEZONE", "Europe/Madrid")
	os.Setenv("COUNTDOWN", "5 minutes")
	os.Setenv("REGION", "eu-west-3" )
	HandleRequest(context.Background())
}