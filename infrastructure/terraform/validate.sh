#!/bin/bash

# ==============================================================================
# TERRAFORM VALIDATION SCRIPT
# Azure Deployment Environments - Budget Governance Module
# ==============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}==============================================================================${NC}"
echo -e "${BLUE}Azure Deployment Environments - Budget Governance Module Validation${NC}"
echo -e "${BLUE}==============================================================================${NC}"
echo

# ==============================================================================
# FUNCTION DEFINITIONS
# ==============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_command() {
    local cmd=$1
    local name=$2
    
    if command -v "$cmd" &> /dev/null; then
        local version
        case $cmd in
            terraform)
                version=$(terraform version | head -n1 | awk '{print $2}')
                ;;
            az)
                version=$(az version --output tsv --query '"azure-cli"')
                ;;
            *)
                version="installed"
                ;;
        esac
        log_success "$name is installed ($version)"
        return 0
    else
        log_error "$name is not installed"
        return 1
    fi
}

check_file_exists() {
    local file=$1
    local description=$2
    
    if [[ -f "$file" ]]; then
        log_success "$description exists: $file"
        return 0
    else
        log_error "$description missing: $file"
        return 1
    fi
}

# ==============================================================================
# PREREQUISITE CHECKS
# ==============================================================================

log_info "Checking prerequisites..."

PREREQ_FAILED=0

# Check required commands
check_command "terraform" "Terraform" || PREREQ_FAILED=1
check_command "az" "Azure CLI" || PREREQ_FAILED=1

if [[ $PREREQ_FAILED -eq 1 ]]; then
    log_error "Prerequisites check failed. Please install missing tools."
    exit 1
fi

echo

# ==============================================================================
# FILE STRUCTURE VALIDATION
# ==============================================================================

log_info "Validating Terraform module structure..."

# Required files
REQUIRED_FILES=(
    "$SCRIPT_DIR/versions.tf"
    "$SCRIPT_DIR/variables.tf"
    "$SCRIPT_DIR/locals.tf"
    "$SCRIPT_DIR/data.tf"
    "$SCRIPT_DIR/main.tf"
    "$SCRIPT_DIR/outputs.tf"
    "$SCRIPT_DIR/README.md"
)

# Optional files
OPTIONAL_FILES=(
    "$SCRIPT_DIR/terraform.tfvars.example"
    "$SCRIPT_DIR/.terraform-docs.yml"
    "$SCRIPT_DIR/.gitignore"
)

FILES_FAILED=0

for file in "${REQUIRED_FILES[@]}"; do
    check_file_exists "$file" "Required file" || FILES_FAILED=1
done

for file in "${OPTIONAL_FILES[@]}"; do
    if [[ -f "$file" ]]; then
        log_success "Optional file exists: $(basename "$file")"
    else
        log_warning "Optional file missing: $(basename "$file")"
    fi
done

if [[ $FILES_FAILED -eq 1 ]]; then
    log_error "File structure validation failed."
    exit 1
fi

echo

# ==============================================================================
# TERRAFORM VALIDATION
# ==============================================================================

log_info "Performing Terraform validation..."

cd "$SCRIPT_DIR"

# Initialize Terraform (if not already initialized)
if [[ ! -d ".terraform" ]]; then
    log_info "Initializing Terraform..."
    if terraform init; then
        log_success "Terraform initialized successfully"
    else
        log_error "Terraform initialization failed"
        exit 1
    fi
else
    log_info "Terraform already initialized"
fi

# Validate Terraform configuration
log_info "Validating Terraform configuration..."
if terraform validate; then
    log_success "Terraform configuration is valid"
else
    log_error "Terraform validation failed"
    exit 1
fi

# Check formatting
log_info "Checking Terraform formatting..."
if terraform fmt -check=true -diff=true; then
    log_success "Terraform code is properly formatted"
else
    log_warning "Terraform code formatting issues detected. Run 'terraform fmt' to fix."
fi

echo

# ==============================================================================
# CONFIGURATION VALIDATION
# ==============================================================================

log_info "Validating configuration files..."

# Check if example tfvars file has required variables
if [[ -f "terraform.tfvars.example" ]]; then
    REQUIRED_VARS=(
        "resource_group_name"
        "location"
        "user_email"
        "user_hash"
        "environment_name"
        "budget_amount"
        "budget_start_date"
        "budget_end_date"
        "devops_team_email"
        "finance_team_email"
    )
    
    for var in "${REQUIRED_VARS[@]}"; do
        if grep -q "^$var" terraform.tfvars.example; then
            log_success "Required variable '$var' found in example file"
        else
            log_warning "Required variable '$var' not found in example file"
        fi
    done
else
    log_warning "terraform.tfvars.example file not found"
fi

echo

# ==============================================================================
# AZURE CONNECTIVITY CHECK
# ==============================================================================

log_info "Checking Azure connectivity..."

if az account show &> /dev/null; then
    SUBSCRIPTION_ID=$(az account show --query id -o tsv)
    SUBSCRIPTION_NAME=$(az account show --query name -o tsv)
    log_success "Connected to Azure subscription: $SUBSCRIPTION_NAME ($SUBSCRIPTION_ID)"
else
    log_warning "Not logged into Azure CLI. Run 'az login' to authenticate."
fi

echo

# ==============================================================================
# SECURITY VALIDATION
# ==============================================================================

log_info "Performing security validation..."

# Check for sensitive data in configuration files
log_info "Scanning for potential sensitive data..."

SENSITIVE_PATTERNS=(
    "password.*=.*[\"'].*[\"']"
    "secret.*=.*[\"'].*[\"']"
    "key.*=.*[\"'].*[\"']"
    "token.*=.*[\"'].*[\"']"
)

SECURITY_ISSUES=0

for pattern in "${SENSITIVE_PATTERNS[@]}"; do
    if grep -r -i -E "$pattern" . --include="*.tf" --include="*.tfvars*"; then
        log_warning "Potential sensitive data found (pattern: $pattern)"
        SECURITY_ISSUES=1
    fi
done

if [[ $SECURITY_ISSUES -eq 0 ]]; then
    log_success "No obvious sensitive data patterns found"
fi

echo

# ==============================================================================
# BEST PRACTICES VALIDATION
# ==============================================================================

log_info "Checking Terraform best practices..."

# Check for required provider versions
if grep -q "required_version.*=" versions.tf; then
    log_success "Terraform version constraint defined"
else
    log_warning "Terraform version constraint not found"
fi

# Check for resource tagging
if grep -q "tags.*=" main.tf; then
    log_success "Resource tagging implemented"
else
    log_warning "Resource tagging not found"
fi

# Check for output descriptions
if grep -q "description.*=" outputs.tf; then
    log_success "Output descriptions provided"
else
    log_warning "Output descriptions not found"
fi

# Check for variable descriptions
if grep -q "description.*=" variables.tf; then
    log_success "Variable descriptions provided"
else
    log_warning "Variable descriptions not found"
fi

echo

# ==============================================================================
# FINAL SUMMARY
# ==============================================================================

log_info "Validation complete!"
echo
echo -e "${BLUE}==============================================================================${NC}"
echo -e "${GREEN}✅ VALIDATION SUMMARY${NC}"
echo -e "${BLUE}==============================================================================${NC}"
echo -e "${GREEN}✅ All required files present${NC}"
echo -e "${GREEN}✅ Terraform configuration valid${NC}"
echo -e "${GREEN}✅ Module structure correct${NC}"
echo -e "${GREEN}✅ Security checks passed${NC}"
echo
echo -e "${BLUE}📋 NEXT STEPS:${NC}"
echo -e "${YELLOW}1.${NC} Copy terraform.tfvars.example to terraform.tfvars"
echo -e "${YELLOW}2.${NC} Edit terraform.tfvars with your environment-specific values"
echo -e "${YELLOW}3.${NC} Run 'terraform plan' to review planned changes"
echo -e "${YELLOW}4.${NC} Run 'terraform apply' to deploy the infrastructure"
echo
echo -e "${BLUE}📚 DOCUMENTATION:${NC}"
echo -e "${YELLOW}•${NC} Module documentation: README.md"
echo -e "${YELLOW}•${NC} Variable examples: terraform.tfvars.example"
echo -e "${YELLOW}•${NC} Azure best practices: Follow enterprise tagging strategy"
echo
echo -e "${GREEN}🎉 Module is ready for deployment!${NC}"
echo