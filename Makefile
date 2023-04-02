TF_COMPONENT	?= aws
TF_DIR			:= ${PWD}/ops/terraform/${TF_COMPONENT}
SSH_DIR			:= ${PWD}/ops/.ssh
SCRIPTS_DIR		:= ${PWD}/ops/scripts
DOCKER_DIR		:= ${PWD}/ops/docker

export SSH_DIR
export TF_DIR
export SCRIPTS_DIR
export DOCKER_DIR

tf-init:
	@cd ${TF_DIR} && terraform init -reconfigure

tf-validate: tf-init new-keypair
	@cd ${TF_DIR} && terraform validate

tf-plan:
	@cd ${TF_DIR} && terraform plan -out=tfplan.out 

tf-apply:
	@cd ${TF_DIR} && terraform apply --auto-approve tfplan.out

tf-output:
	@cd ${TF_DIR} && terraform output -json

new-keypair:
	@mkdir -p ${SSH_DIR} && cd ${SSH_DIR} && ssh-keygen -t rsa -b 4096 -C "ninja-vpn" -q -N "" -f ${SSH_DIR}/id_rsa

deploy:
	@cd ${TF_DIR} && ${SCRIPTS_DIR}/deploy.sh

build-vpn: tf-validate tf-plan tf-apply deploy

destroy-vpn:
	@cd ${TF_DIR} && terraform destroy --auto-approve