TF_COMPONENT    ?= aws
TF_TARGET	    ?= vpn
TF_DIR          := ${PWD}/ops/terraform/${TF_COMPONENT}/${TF_TARGET}
USER            ?= username
REGION           = $(shell yq -r '.region' ./users/${USER}.yaml)

set_user:
	@cat ./common.yaml > ./config.yaml && cat ./users/${USER}.yaml >> ./config.yaml
	@cd ${TF_DIR} && sed 's|<USER>/<REGION>|${USER}/${REGION}|g' ./templates/00-resources.tpl > ./00-resources.tf

tf-init:
	@cd ${TF_DIR} && terraform init -reconfigure

tf-validate: tf-init
	@cd ${TF_DIR} && terraform validate

tf-plan:
	@cd ${TF_DIR} && terraform plan -out=tfplan.out

tf-apply:
	@cd ${TF_DIR} && terraform apply tfplan.out

tf-destroy:
	@cd ${TF_DIR} && terraform destroy

tf-output:
	@cd ${TF_DIR} && terraform output -json

vpn-destroy: set_user tf-init
	@cd ${TF_DIR} && terraform destroy -auto-approve

vpn-deploy: set_user tf-plan tf-apply
	@echo "Deployed! You will receive an email with your VPN configuration after 2 minutes"

vpn:
	./ops/scripts/action.sh ${USER}