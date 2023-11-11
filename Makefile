TF_COMPONENT    ?= aws
TF_TARGET       ?= vpn
TF_DIR          := ${PWD}/ops/terraform/${TF_COMPONENT}/${TF_TARGET}

VPN_REGION      := $(shell yq -r '.region' config.yaml)
VPN_USER        := $(shell echo $(shell yq -r '.email' config.yaml) | cut -d'@' -f1)

KMS_KEY         ?= arn:aws:kms:eu-west-3:877759700856:key/b3ac1035-b1f6-424a-bfe9-a6ec592e7487

-include Makefile.local

decrypt-config:
	@sops -d config.enc.yaml > config.yaml

encrypt-config:
	@sops -e --kms ${KMS_KEY} --input-type yaml config.yaml > config.enc.yaml

tf-init:
	@cd ${TF_DIR} && terraform init -reconfigure

tf-init-vpn:
	@cd ${TF_DIR} && terraform init -reconfigure -backend-config="key=${VPN_USER}/${VPN_REGION}/terraform.tfstate"

tf-plan:
	@cd ${TF_DIR} && terraform plan -out=tfplan.out

tf-apply:
	@cd ${TF_DIR} && terraform apply tfplan.out

tf-deploy: tf-plan tf-apply

tf-destroy:
	@cd ${TF_DIR} && terraform destroy

update-lambda-code:
	@CGO_ENABLED=0 go build -o launch_vpn site/backend/launch_vpn.go && zip ops/terraform/aws/api/launch_vpn.zip launch_vpn && rm launch_vpn

update-lambda-trigger-code:
	@CGO_ENABLED=0 go build -o trigger_lambda site/backend/trigger_lambda.go && zip ops/terraform/aws/api/trigger_lambda.zip trigger_lambda && rm trigger_lambda

update-lambda-authorizer-code:
	@CGO_ENABLED=0 go build -o authorize ops/terraform/aws/api/modules/authorizer/authorize.go && zip ops/terraform/aws/api/modules/authorizer/authorize.zip authorize && rm authorize