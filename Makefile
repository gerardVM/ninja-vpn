TF_COMPONENT    ?= aws
TF_TARGET       ?= api
TF_DIR          := ${PWD}/ops/terraform/${TF_COMPONENT}/${TF_TARGET}

VPN_REGION      := $(shell yq -r '.region' config.yaml)
VPN_USER        := $(shell echo $(shell yq -r '.email' config.yaml) | cut -d'@' -f1)

GOOS            := linux
GOARCH          := amd64 

KMS_KEY         ?= arn:aws:kms:eu-west-3:877759700856:key/b3ac1035-b1f6-424a-bfe9-a6ec592e7487


set-vpn-preferences-file:
	@cd ${TF_DIR} && sed 's|<USER>/<REGION>|${VPN_USER}/${VPN_REGION}|g' ./templates/00-preferences.tpl > ./00-preferences.tf

decrypt-config:
	@sops -d config.enc.yaml > config.yaml

encrypt-config:
	@sops -e --kms ${KMS_KEY} --input-type yaml config.yaml > config.enc.yaml

tf-init:
	@cd ${TF_DIR} && terraform init -reconfigure

tf-validate: tf-init
	@cd ${TF_DIR} && terraform validate

tf-plan:
	@cd ${TF_DIR} && terraform plan -out=tfplan.out

tf-apply:
	@cd ${TF_DIR} && terraform apply tfplan.out

tf-output:
	@cd ${TF_DIR} && terraform output -json

tf-deploy: tf-init tf-plan tf-apply

tf-destroy: tf-init
	@cd ${TF_DIR} && terraform destroy

update-lambda:
	@go build -o launch_vpn sites/backend/launch_vpn.go && zip ops/terraform/aws/api/launch_vpn.zip launch_vpn && rm launch_vpn
	@cd ${TF_DIR} && terraform apply

update-lambda-trigger:
	@go build -o trigger_lambda sites/backend/trigger_lambda.go && zip ops/terraform/aws/api/trigger_lambda.zip trigger_lambda && rm trigger_lambda
	@cd ${TF_DIR} && terraform apply