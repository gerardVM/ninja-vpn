TF_COMPONENT    ?= aws
TF_TARGET       ?= vpn
TF_DIR          := ${PWD}/ops/terraform/${TF_COMPONENT}/${TF_TARGET}
KMS_KEY         ?= arn:aws:kms:eu-west-3:877759700856:key/b3ac1035-b1f6-424a-bfe9-a6ec592e7487

decrypt-config:
	@sops -d config.enc.yaml > config.yaml; fi

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
	@cd ${TF_DIR} && terraform destroy -auto-approve