TF_COMPONENT    ?= aws
TF_DIR          := ${PWD}/ops/terraform/${TF_COMPONENT}
REGION           = $(shell yq -r '.region' ./users/${USER}.yaml)

set_user:
	@cat ./common.yaml > ./config.yaml && cat ./users/${USER}.yaml >> ./config.yaml
	@cd ${TF_DIR} && sed 's|<USER>/<REGION>|${USER}/${REGION}|g' ./templates/00-resources.tpl > ./00-resources.tf

tf-init: set_user
	@cd ${TF_DIR} && terraform init -reconfigure

tf-validate: tf-init
	@cd ${TF_DIR} && terraform validate

tf-plan: set_user
	@cd ${TF_DIR} && terraform init -reconfigure
	@cd ${TF_DIR} && terraform plan -out=tfplan.out

tf-apply:
	@cd ${TF_DIR} && terraform apply tfplan.out

tf-output: set_user
	@cd ${TF_DIR} && terraform output -json

vpn-destroy: set_user tf-init
	@cd ${TF_DIR} && terraform destroy -auto-approve

vpn-deploy: tf-validate tf-plan tf-apply
	@echo "Please, check your email for AWS SES subscription confirmation"
	@echo "Once confirmed, you will receive an email with your VPN configuration after 2 minutes"

vpn:
	./ops/scripts/action.sh ${USER}