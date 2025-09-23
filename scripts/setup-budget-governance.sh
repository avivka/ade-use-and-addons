#!/bin/bash

# Bash script for setting up budget governance for ADE users using Terraform
# This script creates and manages per-user budget allocations
# Compatible with GitHub Actions workflows

set -euo pipefail  # Exit on any error

# Script metadata
SCRIPT_NAME="Setup-BudgetGovernance"
SCRIPT_VERSION="1.0.0"

# Default values
DEFAULT_BUDGET_AMOUNT=200
DEFAULT_ENVIRONMENT_TYPE="development"
DEFAULT_LOCATION="eastus2"
DEFAULT_TERRAFORM_PATH="./infrastructure/terraform"
DEFAULT_DEVOPS_TEAM_EMAIL="devops@company.com"
DEFAULT_FINANCE_TEAM_EMAIL="finance@company.com"
WHAT_IF_MODE=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Function to print colored output
print_color() {
    local color=$1
    shift
    echo -e "${color}$*${NC}"
}

# Function to print usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Setup budget governance for ADE users using Terraform

Required Arguments:
    --subscription-id SUBSCRIPTION_ID          Azure subscription ID
    --user-email USER_EMAIL                     User email for budget allocation
    --environment-name ENVIRONMENT_NAME        Environment name
    --resource-group-name RESOURCE_GROUP       Resource group name

Optional Arguments:
    --budget-amount AMOUNT                      Budget amount in USD (default: $DEFAULT_BUDGET_AMOUNT)
    --environment-type TYPE                     Environment type (default: $DEFAULT_ENVIRONMENT_TYPE)
    --expiration-date DATE                      Expiration date (YYYY-MM-DD, default: 30 days from now)
    --location LOCATION                         Azure location (default: $DEFAULT_LOCATION)
    --terraform-path TERRAFORM_PATH            Terraform module path (default: $DEFAULT_TERRAFORM_PATH)
    --devops-team-email EMAIL                   DevOps team email (default: $DEFAULT_DEVOPS_TEAM_EMAIL)
    --finance-team-email EMAIL                  Finance team email (default: $DEFAULT_FINANCE_TEAM_EMAIL)
    --what-if                                   Plan only, don't apply changes
    --help                                      Show this help message

Environment Variables (can be used instead of arguments):
    AZURE_SUBSCRIPTION_ID
    USER_EMAIL
    ENVIRONMENT_NAME
    BUDGET_AMOUNT
    DEVOPS_TEAM_EMAIL
    FINANCE_TEAM_EMAIL

Examples:
    $0 --subscription-id "12345678-1234-1234-1234-123456789012" \\
       --user-email "user@company.com" \\
       --environment-name "test-env" \\
       --resource-group-name "rg-ade-test-env" \\
       --budget-amount 200

    # Using environment variables
    export AZURE_SUBSCRIPTION_ID="12345678-1234-1234-1234-123456789012"
    export USER_EMAIL="user@company.com"
    $0 --environment-name "test-env" \\
       --resource-group-name "rg-ade-test-env"

EOF
}

# Function to generate user hash
generate_user_hash() {
    local email="$1"
    echo -n "${email,,}" | sha256sum | cut -c1-8
}

# Function to get expiration date (30 days from now)
get_default_expiration_date() {
    if command -v gdate &> /dev/null; then
        # macOS with GNU date (brew install coreutils)
        gdate -d "+30 days" +%Y-%m-%d
    elif date -d "+30 days" &> /dev/null 2>&1; then
        # Linux with GNU date
        date -d "+30 days" +%Y-%m-%d
    else
        # macOS with BSD date
        date -v+30d +%Y-%m-%d
    fi
}

# Function to validate required tools
check_prerequisites() {
    print_color "$CYAN" "🔧 Checking prerequisites..."
    
    local missing_tools=()
    
    # Check for required tools
    if ! command -v az &> /dev/null; then
        missing_tools+=("azure-cli")
    fi
    
    if ! command -v terraform &> /dev/null; then
        missing_tools+=("terraform")
    fi
    
    if ! command -v jq &> /dev/null; then
        missing_tools+=("jq")
    fi
    
    if [[ ${#missing_tools[@]} -ne 0 ]]; then
        print_color "$RED" "❌ Missing required tools: ${missing_tools[*]}"
        print_color "$YELLOW" "Please install the following:"
        for tool in "${missing_tools[@]}"; do
            case $tool in
                "azure-cli")
                    echo "  - Azure CLI: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
                    ;;
                "terraform")
                    echo "  - Terraform: https://terraform.io/downloads"
                    ;;
                "jq")
                    echo "  - jq: https://stedolan.github.io/jq/download/"
                    ;;
            esac
        done
        exit 1
    fi
    
    # Check Terraform version
    local terraform_version
    terraform_version=$(terraform --version | head -n1 | cut -d' ' -f2 | sed 's/v//')
    print_color "$GREEN" "✅ Terraform found: v$terraform_version"
    
    # Check Azure CLI version
    local az_version
    az_version=$(az --version | head -n1 | cut -d' ' -f2)
    print_color "$GREEN" "✅ Azure CLI found: $az_version"
    
    print_color "$GREEN" "✅ All prerequisites met"
}

# Function to validate Azure authentication
check_azure_auth() {
    print_color "$CYAN" "🔐 Checking Azure authentication..."
    
    if ! az account show &> /dev/null; then
        print_color "$YELLOW" "⚠️ Not logged into Azure. Please run 'az login' first."
        exit 1
    fi
    
    local current_subscription
    current_subscription=$(az account show --query id -o tsv)
    
    if [[ "$current_subscription" != "$SUBSCRIPTION_ID" ]]; then
        print_color "$YELLOW" "⚠️ Setting subscription context to: $SUBSCRIPTION_ID"
        if ! az account set --subscription "$SUBSCRIPTION_ID"; then
            print_color "$RED" "❌ Failed to set subscription context"
            exit 1
        fi
    fi
    
    print_color "$GREEN" "✅ Connected to subscription: $SUBSCRIPTION_ID"
}

# Function to validate resource group
check_resource_group() {
    print_color "$CYAN" "📦 Checking resource group..."
    
    if ! az group show --name "$RESOURCE_GROUP_NAME" &> /dev/null; then
        print_color "$RED" "❌ Resource group '$RESOURCE_GROUP_NAME' does not exist"
        print_color "$YELLOW" "Please create it first or run the main environment provisioning workflow."
        exit 1
    fi
    
    print_color "$GREEN" "✅ Resource group found: $RESOURCE_GROUP_NAME"
}

# Function to deploy with Terraform
deploy_terraform() {
    print_color "$CYAN" "🚀 Deploying ADE Budget Governance with Terraform..."
    
    # Check if Terraform path exists
    if [[ ! -d "$TERRAFORM_PATH" ]]; then
        print_color "$RED" "❌ Terraform module path not found: $TERRAFORM_PATH"
        exit 1
    fi
    
    # Save current directory
    local current_dir
    current_dir=$(pwd)
    
    # Navigate to Terraform directory
    cd "$TERRAFORM_PATH"
    
    # Ensure we return to original directory on exit
    trap "cd '$current_dir'" EXIT
    
    # Calculate budget dates
    local start_date end_date
    if command -v gdate &> /dev/null; then
        # macOS with GNU date (brew install coreutils)
        start_date=$(gdate -d "$(gdate +%Y-%m-01)" +%Y-%m-%d)
    elif date -d "$(date +%Y-%m-01)" &> /dev/null 2>&1; then
        # Linux with GNU date
        start_date=$(date -d "$(date +%Y-%m-01)" +%Y-%m-%d)
    else
        # macOS with BSD date
        start_date=$(date -j -f "%Y-%m-%d" "$(date +%Y-%m-01)" +%Y-%m-%d)
    fi
    end_date="$EXPIRATION_DATE"
    
    # Generate user hash
    local user_hash
    user_hash=$(generate_user_hash "$USER_EMAIL")
    
    # Create terraform.tfvars file
    local tfvars_content
    tfvars_content=$(cat << EOF
# Required variables
resource_group_name = "$RESOURCE_GROUP_NAME"
location = "$LOCATION"
user_email = "$USER_EMAIL"
user_hash = "$user_hash"
environment_name = "$ENVIRONMENT_NAME"
budget_amount = $BUDGET_AMOUNT
budget_start_date = "$start_date"
budget_end_date = "$end_date"
devops_team_email = "$DEVOPS_TEAM_EMAIL"
finance_team_email = "$FINANCE_TEAM_EMAIL"

# Alert thresholds (80%, 95%, 100%, 90% forecast)
alert_thresholds = [
  {
    type = "Actual"
    threshold = 80
    operator = "GreaterThan"
  },
  {
    type = "Actual"
    threshold = 95
    operator = "GreaterThan"
  },
  {
    type = "Actual"
    threshold = 100
    operator = "GreaterThan"
  },
  {
    type = "Forecasted"
    threshold = 90
    operator = "GreaterThan"
  }
]

# Optional configuration
environment_type = "$ENVIRONMENT_TYPE"
expiration_date = "$EXPIRATION_DATE"
cost_center = "ADE-Environments"

# Additional tags
additional_tags = {
  "BashScript" = "Setup-BudgetGovernance"
  "UserHash" = "$user_hash"
}
EOF
)
    
    print_color "$CYAN" "📝 Creating terraform.tfvars..."
    if [[ "$WHAT_IF_MODE" == "false" ]]; then
        echo "$tfvars_content" > terraform.tfvars
    else
        print_color "$MAGENTA" "🔍 WhatIf mode - terraform.tfvars content:"
        echo "$tfvars_content"
    fi
    
    # Initialize Terraform
    print_color "$CYAN" "🔧 Initializing Terraform..."
    if [[ "$WHAT_IF_MODE" == "false" ]]; then
        if ! terraform init; then
            print_color "$RED" "❌ Terraform init failed"
            exit 1
        fi
    else
        print_color "$MAGENTA" "🔍 WhatIf mode - skipping terraform init"
    fi
    
    # Plan deployment
    print_color "$CYAN" "📋 Planning Terraform deployment..."
    if [[ "$WHAT_IF_MODE" == "true" ]]; then
        print_color "$MAGENTA" "🔍 Running in WhatIf mode - no resources will be created"
        terraform plan
    else
        if ! terraform plan -out=tfplan; then
            print_color "$RED" "❌ Terraform plan failed"
            exit 1
        fi
        
        # Apply deployment
        print_color "$CYAN" "🚀 Applying Terraform deployment..."
        if ! terraform apply -auto-approve tfplan; then
            print_color "$RED" "❌ Terraform apply failed"
            exit 1
        fi
    fi
    
    print_color "$GREEN" "✅ Budget governance setup completed successfully!"
    
    # Get Terraform outputs
    print_color "$CYAN" "📊 Terraform Outputs:"
    if [[ "$WHAT_IF_MODE" == "false" ]]; then
        terraform output
    fi
    
    # Cleanup
    if [[ "$WHAT_IF_MODE" == "false" && -f "terraform.tfvars" ]]; then
        rm -f terraform.tfvars
    fi
    
    # Return to original directory
    cd "$current_dir"
    trap - EXIT
}

# Function to print summary
print_summary() {
    local user_hash
    user_hash=$(generate_user_hash "$USER_EMAIL")
    
    print_color "$GREEN" "🎉 ADE Budget Governance setup completed successfully!"
    print_color "$YELLOW" "📋 Budget Configuration:"
    echo "   💰 Budget Amount: \$$BUDGET_AMOUNT USD"
    echo "   📅 Start Date: $(date +%Y-%m-01)"
    echo "   📅 End Date: $EXPIRATION_DATE"
    echo "   🚨 Alert Thresholds: 80%, 95%, 100%, 90% forecast"
    echo "   👤 User: $USER_EMAIL ($user_hash)"
    echo "   📧 DevOps Team: $DEVOPS_TEAM_EMAIL"
    echo "   💰 Finance Team: $FINANCE_TEAM_EMAIL"
}

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --subscription-id)
                SUBSCRIPTION_ID="$2"
                shift 2
                ;;
            --user-email)
                USER_EMAIL="$2"
                shift 2
                ;;
            --environment-name)
                ENVIRONMENT_NAME="$2"
                shift 2
                ;;
            --resource-group-name)
                RESOURCE_GROUP_NAME="$2"
                shift 2
                ;;
            --budget-amount)
                BUDGET_AMOUNT="$2"
                shift 2
                ;;
            --environment-type)
                ENVIRONMENT_TYPE="$2"
                shift 2
                ;;
            --expiration-date)
                EXPIRATION_DATE="$2"
                shift 2
                ;;
            --location)
                LOCATION="$2"
                shift 2
                ;;
            --terraform-path)
                TERRAFORM_PATH="$2"
                shift 2
                ;;
            --devops-team-email)
                DEVOPS_TEAM_EMAIL="$2"
                shift 2
                ;;
            --finance-team-email)
                FINANCE_TEAM_EMAIL="$2"
                shift 2
                ;;
            --what-if)
                WHAT_IF_MODE=true
                shift
                ;;
            --help)
                usage
                exit 0
                ;;
            *)
                print_color "$RED" "❌ Unknown argument: $1"
                usage
                exit 1
                ;;
        esac
    done
}

# Main execution function
main() {
    print_color "$GREEN" "💰 Starting ADE Budget Governance Setup with Terraform"
    print_color "$YELLOW" "📋 Script: $SCRIPT_NAME v$SCRIPT_VERSION"
    
    # Parse arguments
    parse_arguments "$@"
    
    # Use environment variables as fallbacks
    SUBSCRIPTION_ID="${SUBSCRIPTION_ID:-${AZURE_SUBSCRIPTION_ID:-}}"
    USER_EMAIL="${USER_EMAIL:-${USER_EMAIL:-}}"
    ENVIRONMENT_NAME="${ENVIRONMENT_NAME:-${ENVIRONMENT_NAME:-}}"
    BUDGET_AMOUNT="${BUDGET_AMOUNT:-${BUDGET_AMOUNT:-$DEFAULT_BUDGET_AMOUNT}}"
    DEVOPS_TEAM_EMAIL="${DEVOPS_TEAM_EMAIL:-${DEVOPS_TEAM_EMAIL:-$DEFAULT_DEVOPS_TEAM_EMAIL}}"
    FINANCE_TEAM_EMAIL="${FINANCE_TEAM_EMAIL:-${FINANCE_TEAM_EMAIL:-$DEFAULT_FINANCE_TEAM_EMAIL}}"
    
    # Set defaults
    ENVIRONMENT_TYPE="${ENVIRONMENT_TYPE:-$DEFAULT_ENVIRONMENT_TYPE}"
    LOCATION="${LOCATION:-$DEFAULT_LOCATION}"
    TERRAFORM_PATH="${TERRAFORM_PATH:-$DEFAULT_TERRAFORM_PATH}"
    EXPIRATION_DATE="${EXPIRATION_DATE:-$(get_default_expiration_date)}"
    
    # Validate required parameters
    local missing_params=()
    [[ -z "${SUBSCRIPTION_ID:-}" ]] && missing_params+=("subscription-id")
    [[ -z "${USER_EMAIL:-}" ]] && missing_params+=("user-email")
    [[ -z "${ENVIRONMENT_NAME:-}" ]] && missing_params+=("environment-name")
    [[ -z "${RESOURCE_GROUP_NAME:-}" ]] && missing_params+=("resource-group-name")
    
    if [[ ${#missing_params[@]} -ne 0 ]]; then
        print_color "$RED" "❌ Missing required parameters: ${missing_params[*]}"
        echo
        usage
        exit 1
    fi
    
    # Validate budget amount is a number
    if ! [[ "$BUDGET_AMOUNT" =~ ^[0-9]+$ ]]; then
        print_color "$RED" "❌ Budget amount must be a number: $BUDGET_AMOUNT"
        exit 1
    fi
    
    # Generate user hash for display
    local user_hash
    user_hash=$(generate_user_hash "$USER_EMAIL")
    
    # Print configuration summary
    print_color "$YELLOW" "📋 Configuration Summary:"
    echo "   Subscription ID: $SUBSCRIPTION_ID"
    echo "   User Email: $USER_EMAIL"
    echo "   Environment Name: $ENVIRONMENT_NAME"
    echo "   Resource Group: $RESOURCE_GROUP_NAME"
    echo "   Budget Amount: \$$BUDGET_AMOUNT USD"
    echo "   Environment Type: $ENVIRONMENT_TYPE"
    echo "   Expiration Date: $EXPIRATION_DATE"
    echo "   Location: $LOCATION"
    echo "   Terraform Path: $TERRAFORM_PATH"
    echo "   User Hash: $user_hash"
    echo "   What-If Mode: $WHAT_IF_MODE"
    
    # Execute deployment steps
    check_prerequisites
    check_azure_auth
    check_resource_group
    deploy_terraform
    print_summary
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi