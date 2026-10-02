SHELL := /bin/bash

ENV  ?= dev
ENVS := dev staging prod
DIR  := environments/$(ENV)
PLAN := tfplan

.DEFAULT_GOAL := help

.PHONY: help check-env init plan apply destroy output fmt fmt-check validate validate-all \
        lint test security-scan ci backend-init backend-destroy clean

help: ## Muestra esta ayuda
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'

check-env:
	@if [[ ! " $(ENVS) " =~ " $(ENV) " ]]; then \
		echo "ENV invalido: '$(ENV)'. Valores permitidos: $(ENVS)"; exit 1; \
	fi

## --- Ciclo de vida por ambiente (ENV=dev|staging|prod) ---

init: check-env ## Inicializa el ambiente con el backend remoto
	terraform -chdir=$(DIR) init

plan: check-env ## Genera un plan y lo guarda en environments/$ENV/tfplan
	terraform -chdir=$(DIR) plan -out=$(PLAN)

apply: check-env ## Aplica exactamente el plan guardado por 'make plan'
	terraform -chdir=$(DIR) apply $(PLAN)
	@rm -f $(DIR)/$(PLAN)

destroy: check-env ## Destruye la infraestructura del ambiente
	terraform -chdir=$(DIR) destroy

output: check-env ## Muestra los outputs del ambiente
	terraform -chdir=$(DIR) output

## --- Calidad de codigo ---

fmt: ## Formatea todo el codigo
	terraform fmt -recursive

fmt-check: ## Verifica formato sin modificar archivos (CI)
	terraform fmt -recursive -check -diff

validate: check-env ## Valida el ambiente sin tocar el backend remoto
	terraform -chdir=$(DIR) init -backend=false -input=false >/dev/null
	terraform -chdir=$(DIR) validate

validate-all: ## Valida backend/ y todos los ambientes
	@for d in backend $(addprefix environments/,$(ENVS)); do \
		echo "==> $$d"; \
		terraform -chdir=$$d init -backend=false -input=false >/dev/null && \
		terraform -chdir=$$d validate || exit 1; \
	done

lint: ## Ejecuta TFLint en todo el repositorio
	tflint --init --config "$(CURDIR)/.tflint.hcl"
	tflint --recursive --config "$(CURDIR)/.tflint.hcl"

test: ## Ejecuta los tests de modulos (terraform test + mock providers)
	@for m in modules/*/; do \
		echo "==> $$m"; \
		terraform -chdir=$$m init -backend=false -input=false >/dev/null && \
		terraform -chdir=$$m test || exit 1; \
	done

security-scan: ## Escaneo de seguridad estatico (Checkov)
	checkov -d . --config-file .checkov.yaml

ci: fmt-check validate-all lint test security-scan ## Ejecuta localmente los mismos checks que CI

## --- Backend de state (bootstrap, una sola vez) ---

backend-init: ## Crea el bucket S3 y la tabla DynamoDB del state
	terraform -chdir=backend init
	terraform -chdir=backend apply

backend-destroy: ## Destruye el backend (requiere quitar prevent_destroy)
	terraform -chdir=backend destroy

## --- Limpieza ---

# Borra providers descargados y planes. NUNCA borra state (*.tfstate) ni
# .terraform.lock.hcl: el primero es irrecuperable y el segundo se versiona.
# Conserva el symlink .terraform -> .terraform.nosync (exclusion de iCloud).
clean: ## Borra caches de providers y planes (nunca state ni lock files)
	find . -type d -name ".terraform" -prune -exec rm -rf {} +
	find . -type d -name ".terraform.nosync" -prune -exec sh -c 'rm -rf "$$1"/providers "$$1"/modules' _ {} \;
	find . -type f -name "$(PLAN)" -delete
