TF_COMPONENT    ?= aws
TF_DIR          := ${PWD}/ops/terraform/${TF_COMPONENT}
SSH_DIR         := ${PWD}/ops/.ssh

tf-init:
	@cd ${TF_DIR} && terraform init -reconfigure

tf-validate: tf-init
	@cd ${TF_DIR} && terraform validate

tf-apply:
	@cd ${TF_DIR} && terraform apply

tf-output:
	@cd ${TF_DIR} && terraform output -json

tf-destroy:
	@cd ${TF_DIR} && terraform destroy

vpn-deploy: tf-validate tf-apply
	@echo "Please, check your email for AWS SES subscription confirmation"
	@echo "Once confirmed, you will receive an email with your VPN configuration after 2 minutes"