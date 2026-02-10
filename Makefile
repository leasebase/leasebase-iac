# LeaseBase Infrastructure Makefile
# ================================
# Terraform-based infrastructure management for multi-account AWS setup.
#
# Usage:
#   make bootstrap ENV=dev       - Bootstrap remote state backend
#   make init ENV=dev            - Initialize Terraform for environment
#   make plan ENV=dev            - Plan changes for environment
#   make apply ENV=dev           - Apply changes to environment
#   make destroy ENV=dev         - Destroy environment (with safety prompts)
#   make validate                - Validate all environments
#   make fmt                     - Format all Terraform code
#   make fmt-check               - Check formatting without changes

.PHONY: help bootstrap init plan apply destroy validate fmt fmt-check clean

# Default target
help:
	@echo "LeaseBase Infrastructure Management"
	@echo "===================================="
	@echo ""
	@echo "Environment Commands (requires ENV=dev|qa|uat|prod):"
	@echo "  make bootstrap ENV=<env>   Bootstrap remote state backend for account"
	@echo "  make init ENV=<env>        Initialize Terraform for environment"
	@echo "  make plan ENV=<env>        Plan infrastructure changes"
	@echo "  make apply ENV=<env>       Apply infrastructure changes"
	@echo "  make destroy ENV=<env>     Destroy infrastructure (with safety prompts)"
	@echo "  make output ENV=<env>      Show Terraform outputs"
	@echo ""
	@echo "Global Commands:"
	@echo "  make validate              Validate all environments"
	@echo "  make fmt                   Format all Terraform code"
	@echo "  make fmt-check             Check formatting (CI mode)"
	@echo "  make clean                 Remove .terraform directories"
	@echo ""
	@echo "Examples:"
	@echo "  make plan ENV=dev"
	@echo "  make apply ENV=prod"
	@echo "  make destroy ENV=dev"

# Validate ENV is set for environment-specific commands
check-env:
ifndef ENV
	$(error ENV is required. Use: make <target> ENV=dev|qa|uat|prod)
endif
ifeq ($(filter $(ENV),dev qa uat prod),)
	$(error ENV must be one of: dev, qa, uat, prod)
endif

# Directory paths
ENV_DIR = environments/$(ENV)
BOOTSTRAP_DIR = bootstrap

# ============================================================================
# Bootstrap Commands
# ============================================================================

# Bootstrap remote state backend in the target account
# This should be run ONCE per account before using Terraform
bootstrap: check-env
	@echo "============================================"
	@echo "Bootstrapping remote state for $(ENV)"
	@echo "============================================"
	@echo ""
	@echo "This will create:"
	@echo "  - S3 bucket for Terraform state"
	@echo "  - DynamoDB table for state locking"
	@echo "  - IAM role for Terraform access"
	@echo ""
	@read -p "Continue? [y/N] " confirm && [ "$$confirm" = "y" ] || exit 1
	@cd $(BOOTSTRAP_DIR) && \
		terraform init && \
		terraform apply -var="environment=$(ENV)"

# ============================================================================
# Environment Commands
# ============================================================================

# Initialize Terraform for the environment
init: check-env
	@echo "Initializing Terraform for $(ENV)..."
	@if [ ! -f "$(ENV_DIR)/backend.hcl" ]; then \
		echo "ERROR: $(ENV_DIR)/backend.hcl not found."; \
		echo "Copy $(ENV_DIR)/backend.hcl.example and fill in your account values."; \
		exit 1; \
	fi
	@cd $(ENV_DIR) && terraform init -backend-config=backend.hcl

# Plan changes for the environment
plan: check-env
	@echo "Planning changes for $(ENV)..."
	@if [ ! -f "$(ENV_DIR)/terraform.tfvars" ]; then \
		echo "WARNING: $(ENV_DIR)/terraform.tfvars not found."; \
		echo "Using defaults. Copy terraform.tfvars.example for customization."; \
	fi
	@cd $(ENV_DIR) && terraform plan -out=$(ENV).tfplan

# Apply changes to the environment
apply: check-env
	@echo "============================================"
	@echo "Applying changes to $(ENV)"
	@echo "============================================"
	@if [ "$(ENV)" = "prod" ]; then \
		echo ""; \
		echo "⚠️  WARNING: You are about to modify PRODUCTION!"; \
		echo ""; \
		read -p "Type 'prod' to confirm: " confirm && [ "$$confirm" = "prod" ] || exit 1; \
	fi
	@if [ -f "$(ENV_DIR)/$(ENV).tfplan" ]; then \
		cd $(ENV_DIR) && terraform apply $(ENV).tfplan; \
	else \
		echo "No plan file found. Running plan first..."; \
		cd $(ENV_DIR) && terraform apply; \
	fi

# Destroy the environment (with safety prompts)
destroy: check-env
	@./scripts/destroy.sh $(ENV)

# Show outputs for the environment
output: check-env
	@cd $(ENV_DIR) && terraform output

# ============================================================================
# Global Commands
# ============================================================================

# Validate all environments
validate:
	@echo "Validating all environments..."
	@for env in dev qa uat prod; do \
		if [ -d "environments/$$env" ]; then \
			echo ""; \
			echo "Validating $$env..."; \
			(cd environments/$$env && terraform init -backend=false && terraform validate) || exit 1; \
		fi; \
	done
	@echo ""
	@echo "✅ All environments validated successfully"

# Validate single environment (useful for development)
validate-env: check-env
	@echo "Validating $(ENV)..."
	@cd $(ENV_DIR) && terraform init -backend=false && terraform validate

# Format all Terraform code
fmt:
	@echo "Formatting Terraform code..."
	@terraform fmt -recursive
	@echo "✅ Formatting complete"

# Check formatting (for CI)
fmt-check:
	@echo "Checking Terraform formatting..."
	@terraform fmt -check -recursive
	@echo "✅ Formatting check passed"

# Clean up .terraform directories
clean:
	@echo "Cleaning up .terraform directories..."
	@find . -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true
	@find . -name "*.tfplan" -delete 2>/dev/null || true
	@echo "✅ Cleanup complete"

# ============================================================================
# Development Helpers
# ============================================================================

# Show what would be destroyed (dry-run)
destroy-plan: check-env
	@echo "Planning destruction for $(ENV)..."
	@cd $(ENV_DIR) && terraform plan -destroy

# Refresh state without making changes
refresh: check-env
	@cd $(ENV_DIR) && terraform refresh

# Import existing resources
import: check-env
ifndef RESOURCE
	$(error RESOURCE is required. Use: make import ENV=<env> RESOURCE=<addr> ID=<id>)
endif
ifndef ID
	$(error ID is required. Use: make import ENV=<env> RESOURCE=<addr> ID=<id>)
endif
	@cd $(ENV_DIR) && terraform import $(RESOURCE) $(ID)
