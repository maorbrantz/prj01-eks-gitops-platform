.PHONY: help bootstrap plan up apply down demo argocd

AWS_PROFILE ?= prj01
DEV_DIR := terraform/envs/dev
HELM_BIN ?= helm

help:
	@echo "targets: bootstrap plan up apply down argocd demo"
	@echo "  plan          terraform plan for the dev env"
	@echo "  up / apply    terraform apply for the dev env (needs FORCE=1)"
	@echo "  down          terraform destroy for the dev env (needs FORCE=1)"
	@echo "  argocd        install argocd and apply the root app (needs a live cluster)"

bootstrap:
	cd terraform/bootstrap && \
		AWS_PROFILE=$(AWS_PROFILE) terraform fmt -check && \
		AWS_PROFILE=$(AWS_PROFILE) terraform init && \
		AWS_PROFILE=$(AWS_PROFILE) terraform validate && \
		AWS_PROFILE=$(AWS_PROFILE) terraform plan

plan:
	cd $(DEV_DIR) && \
		AWS_PROFILE=$(AWS_PROFILE) terraform init && \
		AWS_PROFILE=$(AWS_PROFILE) terraform validate && \
		AWS_PROFILE=$(AWS_PROFILE) terraform plan

up: apply

apply:
	@echo "apply provisions real AWS resources and requires explicit human approval."
	@echo "re-run with FORCE=1 once you have reviewed the plan: make apply FORCE=1"
ifeq ($(FORCE),1)
	cd $(DEV_DIR) && AWS_PROFILE=$(AWS_PROFILE) terraform apply
endif

down:
	@echo "down destroys the dev cluster and its network. this is not reversible."
	@echo "re-run with FORCE=1 to proceed: make down FORCE=1"
ifeq ($(FORCE),1)
	cd $(DEV_DIR) && AWS_PROFILE=$(AWS_PROFILE) terraform destroy
endif

argocd:
	HELM_BIN=$(HELM_BIN) scripts/bootstrap-cluster.sh

demo:
	@echo "demo: not implemented yet"
