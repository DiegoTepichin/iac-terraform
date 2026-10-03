SHELL := /bin/bash

ENV  ?= dev
ENVS := dev staging prod
DIR  := environments/$(ENV)
PLAN := tfplan

.DEFAULT_GOAL := help

.PHONY: help check-env init plan apply destroy output fmt fmt-check validate validate-all \
        lint test docs security-scan ci backend-init backend-config backend-destroy clean

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'

check-env:
	@if [[ ! " $(ENVS) " =~ " $(ENV) " ]]; then \
		echo "Invalid ENV '$(ENV)'. Allowed values: $(ENVS)"; exit 1; \
	fi

## --- Per-environment lifecycle (ENV=dev|staging|prod) ---

init: check-env ## Initialize an environment against the remote backend
	@test -f $(DIR)/backend.hcl || { echo "Missing $(DIR)/backend.hcl. Run 'make backend-config' first."; exit 1; }
	terraform -chdir=$(DIR) init -backend-config=backend.hcl

plan: check-env ## Create a plan and save it to environments/$ENV/tfplan
	terraform -chdir=$(DIR) plan -out=$(PLAN)

apply: check-env ## Apply exactly the plan saved by 'make plan'
	terraform -chdir=$(DIR) apply $(PLAN)
	@rm -f $(DIR)/$(PLAN)

destroy: check-env ## Destroy the environment
	terraform -chdir=$(DIR) destroy

output: check-env ## Show the environment outputs
	terraform -chdir=$(DIR) output

## --- Code quality (no AWS credentials needed) ---

fmt: ## Format all Terraform files
	terraform fmt -recursive

fmt-check: ## Check formatting without changing files
	terraform fmt -recursive -check -diff

validate: check-env ## Validate one environment without touching the backend
	terraform -chdir=$(DIR) init -backend=false -input=false >/dev/null
	terraform -chdir=$(DIR) validate

validate-all: ## Validate backend/ and every environment
	@for d in backend $(addprefix environments/,$(ENVS)); do \
		echo "==> $$d"; \
		terraform -chdir=$$d init -backend=false -input=false >/dev/null && \
		terraform -chdir=$$d validate || exit 1; \
	done

lint: ## Run TFLint across the repository
	tflint --init --config "$(CURDIR)/.tflint.hcl"
	tflint --recursive --config "$(CURDIR)/.tflint.hcl"

test: ## Run module tests (terraform test with a mocked AWS provider)
	@for m in modules/*/; do \
		echo "==> $$m"; \
		terraform -chdir=$$m init -backend=false -input=false >/dev/null && \
		terraform -chdir=$$m test || exit 1; \
	done

docs: ## Regenerate the inputs/outputs section of each module README
	@for m in modules/*/; do terraform-docs -c .terraform-docs.yml $$m; done

security-scan: ## Static security scan with Checkov
	checkov -d . --config-file .checkov.yaml

ci: fmt-check validate-all lint test security-scan ## Run the same checks as CI

## --- State backend (one-time bootstrap) ---

backend-init: ## Create the S3 bucket and DynamoDB table for remote state
	terraform -chdir=backend init
	terraform -chdir=backend apply

backend-config: ## Write environments/*/backend.hcl from the backend outputs
	@bucket=$$(terraform -chdir=backend output -raw state_bucket) && \
	for e in $(ENVS); do \
		echo "bucket = \"$$bucket\"" > environments/$$e/backend.hcl; \
		echo "wrote environments/$$e/backend.hcl"; \
	done

backend-destroy: ## Destroy the backend (requires removing prevent_destroy first)
	terraform -chdir=backend destroy

## --- Cleanup ---

# Removes downloaded providers and saved plans. Never removes state (*.tfstate),
# which is unrecoverable, or root module lock files, which are versioned.
clean: ## Remove provider caches and saved plans (never state or lock files)
	find . -type d -name ".terraform" -prune -exec rm -rf {} +
	find . -type d -name ".terraform.nosync" -prune -exec sh -c 'rm -rf "$$1"/providers "$$1"/modules' _ {} \;
	find . -type f -name "$(PLAN)" -delete
