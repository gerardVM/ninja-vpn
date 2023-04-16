TF_COMPONENT    ?= aws
TF_DIR          := ${PWD}/ops/terraform/${TF_COMPONENT}
SSH_DIR         := ${PWD}/ops/.ssh

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

tf-destroy:
	@cd ${TF_DIR} && terraform destroy

tf-add-backend:
	@./ops/scripts/s3-backend.sh > ${TF_DIR}/05-backend.tf

vpn-deploy: tf-add-backend tf-validate tf-plan tf-apply
	@echo "Please, check your email for AWS SES subscription confirmation"
	@echo "Once confirmed, you will receive an email with your VPN configuration after 2 minutes"