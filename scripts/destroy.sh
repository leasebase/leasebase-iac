#!/usr/bin/env bash
#
# LeaseBase Infrastructure Destroy Script
# ========================================
# Safe destruction of environment infrastructure with multiple confirmation steps.
#
# Usage:
#   ./scripts/destroy.sh <environment>
#   ./scripts/destroy.sh dev
#   ./scripts/destroy.sh prod
#
# Safety features:
#   - Environment validation
#   - AWS account ID verification
#   - Extra confirmation for production
#   - Dry-run option
#   - Resource listing before destruction

set -euo pipefail

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# Functions
log_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

show_usage() {
    echo "Usage: $0 <environment> [--dry-run]"
    echo ""
    echo "Environments: dev, qa, uat, prod"
    echo ""
    echo "Options:"
    echo "  --dry-run    Show what would be destroyed without making changes"
    echo ""
    echo "Examples:"
    echo "  $0 dev"
    echo "  $0 prod --dry-run"
}

# Validate environment
validate_environment() {
    local env=$1
    case $env in
        dev|qa|uat|prod)
            return 0
            ;;
        *)
            log_error "Invalid environment: $env"
            log_error "Must be one of: dev, qa, uat, prod"
            exit 1
            ;;
    esac
}

# Get current AWS account ID
get_aws_account_id() {
    aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "UNKNOWN"
}

# Main script
main() {
    local env=""
    local dry_run=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                dry_run=true
                shift
                ;;
            --help|-h)
                show_usage
                exit 0
                ;;
            *)
                if [[ -z "$env" ]]; then
                    env=$1
                else
                    log_error "Unknown argument: $1"
                    show_usage
                    exit 1
                fi
                shift
                ;;
        esac
    done

    # Check if environment is provided
    if [[ -z "$env" ]]; then
        log_error "Environment is required"
        show_usage
        exit 1
    fi

    # Validate environment
    validate_environment "$env"

    local env_dir="$REPO_ROOT/environments/$env"

    # Check if environment directory exists
    if [[ ! -d "$env_dir" ]]; then
        log_error "Environment directory not found: $env_dir"
        exit 1
    fi

    # Get AWS account info
    local account_id
    account_id=$(get_aws_account_id)

    echo ""
    echo "============================================"
    echo -e "  ${RED}INFRASTRUCTURE DESTRUCTION${NC}"
    echo "============================================"
    echo ""
    log_info "Environment:  $env"
    log_info "AWS Account:  $account_id"
    log_info "Directory:    $env_dir"
    echo ""

    # Extra warnings for production
    if [[ "$env" == "prod" ]]; then
        echo ""
        echo -e "${RED}╔═══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${RED}║                                                               ║${NC}"
        echo -e "${RED}║   ⚠️  WARNING: YOU ARE ABOUT TO DESTROY PRODUCTION!          ║${NC}"
        echo -e "${RED}║                                                               ║${NC}"
        echo -e "${RED}║   This action is IRREVERSIBLE and will delete:               ║${NC}"
        echo -e "${RED}║   - VPC and all networking resources                         ║${NC}"
        echo -e "${RED}║   - Security groups                                          ║${NC}"
        echo -e "${RED}║   - IAM roles                                                ║${NC}"
        echo -e "${RED}║   - VPC endpoints                                            ║${NC}"
        echo -e "${RED}║                                                               ║${NC}"
        echo -e "${RED}╚═══════════════════════════════════════════════════════════════╝${NC}"
        echo ""
    fi

    # Dry run mode
    if [[ "$dry_run" == true ]]; then
        log_warn "DRY RUN MODE - No changes will be made"
        echo ""
        log_info "Running terraform plan -destroy..."
        echo ""
        cd "$env_dir"
        terraform plan -destroy
        echo ""
        log_success "Dry run complete. No resources were destroyed."
        exit 0
    fi

    # Confirmation prompts
    echo ""
    log_warn "This will PERMANENTLY DESTROY all infrastructure in the $env environment."
    echo ""

    # First confirmation
    read -p "Are you sure you want to continue? (yes/no): " confirm1
    if [[ "$confirm1" != "yes" ]]; then
        log_info "Destruction cancelled."
        exit 0
    fi

    # Verify AWS account ID
    echo ""
    log_info "Please verify the AWS Account ID to continue."
    read -p "Enter the last 4 digits of account $account_id: " account_verify
    local last4="${account_id: -4}"
    if [[ "$account_verify" != "$last4" ]]; then
        log_error "Account ID verification failed. Destruction cancelled."
        exit 1
    fi
    log_success "Account ID verified."

    # Extra confirmation for production
    if [[ "$env" == "prod" ]]; then
        echo ""
        log_warn "FINAL PRODUCTION CONFIRMATION"
        read -p "Type 'destroy production' to proceed: " prod_confirm
        if [[ "$prod_confirm" != "destroy production" ]]; then
            log_info "Production destruction cancelled."
            exit 0
        fi
    fi

    # Show what will be destroyed
    echo ""
    log_info "Planning destruction..."
    echo ""
    cd "$env_dir"
    terraform plan -destroy -out=destroy.tfplan

    # Final confirmation
    echo ""
    log_warn "The above resources will be PERMANENTLY DESTROYED."
    read -p "Apply destruction? (yes/no): " final_confirm
    if [[ "$final_confirm" != "yes" ]]; then
        log_info "Destruction cancelled."
        rm -f destroy.tfplan
        exit 0
    fi

    # Execute destruction
    echo ""
    log_info "Destroying infrastructure..."
    terraform apply destroy.tfplan

    # Cleanup
    rm -f destroy.tfplan

    echo ""
    log_success "Infrastructure in $env environment has been destroyed."
    echo ""
}

main "$@"
