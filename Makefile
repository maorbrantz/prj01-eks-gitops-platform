.PHONY: help bootstrap up down plan apply demo

help:
	@echo "targets: bootstrap up down plan apply demo"

bootstrap:
	cd terraform/bootstrap && \
		AWS_PROFILE=prj01 terraform fmt -check && \
		AWS_PROFILE=prj01 terraform init && \
		AWS_PROFILE=prj01 terraform validate && \
		AWS_PROFILE=prj01 terraform plan

up:
	@echo "up: not implemented yet"

down:
	@echo "down: not implemented yet"

plan:
	@echo "plan: not implemented yet"

apply:
	@echo "apply: not implemented yet"

demo:
	@echo "demo: not implemented yet"
