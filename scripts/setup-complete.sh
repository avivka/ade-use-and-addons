#!/bin/bash

# Complete Setup Script for ADE Enterprise Extensions using Terraform
# This script deploys the entire solution with proper error handling and validation
# Compatible with GitHub Actions workflows

set -euo pipefail  # Exit on any error

# Script metadata
SCRIPT_NAME="Setup-Complete"
SCRIPT_VERSION="1.0.0"

# Default values
DEFAULT_INTEGRATION_RG_NAME="rg-ade-enterprise-integration"
DEFAULT_LOCATION="eastus2"
DEFAULT_LOGIC_APP_NAME="ade-slack-integration-prod"
DEFAULT_TERRAFORM_PATH="./infrastructure/terraform/complete"
DEFAULT_DEVOPS_TEAM_EMAIL="devops@company.com"
DEFAULT_FINANCE_TEAM_EMAIL="finance@company.com"
WHAT_IF_MODE=false
SKIP_SLACK_INTEGRATION=false
FORCE_MODE=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Function to print colored output
print_color() {
    local color=$1
    shift
    echo -e "${color}$*${NC}"
}

# Function to display banner
show_banner() {
    print_color "$CYAN" "╔═══════════════════════════════════════════════════════════════════════════════╗"
    print_color "$CYAN" "║                                                                               ║"
    print_color "$CYAN" "║         🚀 Azure Deployment Environments - Enterprise Extensions              ║"
    print_color "$CYAN" "║                                                                               ║"
    print_color "$CYAN" "║         Complete setup for Slack integration, budget governance,             ║"
    print_color "$CYAN" "║         and GitHub Actions workflow automation                               ║"
    print_color "$CYAN" "║                                                                               ║"
    print_color "$CYAN" "╚═══════════════════════════════════════════════════════════════════════════════╝"
    echo
}

# Function to print usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Deploy complete ADE Enterprise Extensions solution using Terraform

Required Arguments:
    --subscription-id SUBSCRIPTION_ID          Azure subscription ID
    --slack-webhook-url WEBHOOK_URL             Slack webhook URL
    --ade-resource-group-name ADE_RG            ADE resource group name
    --ade-dev-center-name DEV_CENTER            ADE dev center name

Optional Arguments:
    --integration-resource-group-name RG_NAME   Integration resource group name (default: $DEFAULT_INTEGRATION_RG_NAME)
    --location LOCATION                         Azure location (default: $DEFAULT_LOCATION)
    --logic-app-name LOGIC_APP_NAME            Logic app name (default: $DEFAULT_LOGIC_APP_NAME)
    --terraform-path TERRAFORM_PATH            Terraform module path (default: $DEFAULT_TERRAFORM_PATH)
    --devops-team-email EMAIL                   DevOps team email (default: $DEFAULT_DEVOPS_TEAM_EMAIL)
    --finance-team-email EMAIL                  Finance team email (default: $DEFAULT_FINANCE_TEAM_EMAIL)
    --what-if                                   Plan only, don't apply changes
    --skip-slack-integration                    Skip Slack integration deployment
    --force                                     Force deployment without confirmation
    --help                                      Show this help message

Environment Variables (can be used instead of arguments):
    AZURE_SUBSCRIPTION_ID
    SLACK_WEBHOOK_URL
    ADE_RESOURCE_GROUP_NAME
    ADE_DEV_CENTER_NAME
    DEVOPS_TEAM_EMAIL
    FINANCE_TEAM_EMAIL

Examples:
    $0 --subscription-id "12345678-1234-1234-1234-123456789012" \\
       --slack-webhook-url "https://hooks.slack.com/services/..." \\
       --ade-resource-group-name "rg-ade-devcenter" \\
       --ade-dev-center-name "dc-company-ade"

    # Using environment variables
    export AZURE_SUBSCRIPTION_ID="12345678-1234-1234-1234-123456789012"
    export SLACK_WEBHOOK_URL="https://hooks.slack.com/services/..."
    $0 --ade-resource-group-name "rg-ade-devcenter" \\
       --ade-dev-center-name "dc-company-ade" \\
       --what-if

EOF
}

# Function to validate required tools
check_prerequisites() {
    print_color "$CYAN" "🔍 Validating prerequisites..."
    
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
    
    if ! command -v git &> /dev/null; then
        missing_tools+=("git")
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
                "git")
                    echo "  - Git: https://git-scm.com/downloads"
                    ;;
            esac
        done
        exit 1
    fi
    
    # Check versions
    local terraform_version az_version
    terraform_version=$(terraform --version | head -n1 | cut -d' ' -f2 | sed 's/v//')
    az_version=$(az --version | head -n1 | cut -d' ' -f2)
    
    print_color "$GREEN" "✅ Terraform found: v$terraform_version"
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

# Function to create integration resource group
create_integration_resource_group() {
    print_color "$CYAN" "📦 Setting up integration resource group..."
    
    if ! az group show --name "$INTEGRATION_RESOURCE_GROUP_NAME" &> /dev/null; then
        print_color "$YELLOW" "⚠️ Resource group '$INTEGRATION_RESOURCE_GROUP_NAME' does not exist. Creating..."
        if [[ "$WHAT_IF_MODE" == "false" ]]; then
            if ! az group create --name "$INTEGRATION_RESOURCE_GROUP_NAME" --location "$LOCATION"; then
                print_color "$RED" "❌ Failed to create integration resource group"
                exit 1
            fi
        fi
        print_color "$GREEN" "✅ Integration resource group created: $INTEGRATION_RESOURCE_GROUP_NAME"
    else
        print_color "$GREEN" "✅ Integration resource group exists: $INTEGRATION_RESOURCE_GROUP_NAME"
    fi
}

# Function to validate ADE resources
validate_ade_resources() {
    print_color "$CYAN" "🔍 Validating ADE resources..."
    
    # Check ADE resource group
    if ! az group show --name "$ADE_RESOURCE_GROUP_NAME" &> /dev/null; then
        print_color "$RED" "❌ ADE Resource Group '$ADE_RESOURCE_GROUP_NAME' not found"
        exit 1
    fi
    
    # Check ADE dev center
    if ! az resource show --resource-group "$ADE_RESOURCE_GROUP_NAME" --name "$ADE_DEV_CENTER_NAME" --resource-type "Microsoft.DevCenter/devcenters" &> /dev/null; then
        print_color "$RED" "❌ ADE Dev Center '$ADE_DEV_CENTER_NAME' not found in resource group '$ADE_RESOURCE_GROUP_NAME'"
        exit 1
    fi
    
    print_color "$GREEN" "✅ ADE resources validated"
}

# Function to deploy complete solution with Terraform
deploy_complete_terraform() {
    print_color "$CYAN" "🚀 Deploying complete ADE solution with Terraform..."
    
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
        end_date=$(gdate -d "+30 days" +%Y-%m-%d)
    elif date -d "$(date +%Y-%m-01)" &> /dev/null 2>&1; then
        # Linux with GNU date
        start_date=$(date -d "$(date +%Y-%m-01)" +%Y-%m-%d)
        end_date=$(date -d "+30 days" +%Y-%m-%d)
    else
        # macOS with BSD date
        start_date=$(date -j -f "%Y-%m-%d" "$(date +%Y-%m-01)" +%Y-%m-%d)
        end_date=$(date -v+30d +%Y-%m-%d)
    fi
    
    # Create terraform.tfvars file
    local tfvars_content
    tfvars_content=$(cat << EOF
# Required variables
resource_group_name = "$INTEGRATION_RESOURCE_GROUP_NAME"
location = "$LOCATION"
user_email = "admin@company.com"
user_hash = "admin001"
environment_name = "ade-enterprise"
budget_amount = 1000
budget_start_date = "$start_date"
budget_end_date = "$end_date"
devops_team_email = "$DEVOPS_TEAM_EMAIL"
finance_team_email = "$FINANCE_TEAM_EMAIL"

# Slack integration
slack_integration_name = "$LOGIC_APP_NAME"
slack_webhook_url = "$SLACK_WEBHOOK_URL"
event_grid_topic_name = "ade-events"
ade_resource_group_name = "$ADE_RESOURCE_GROUP_NAME"
ade_dev_center_name = "$ADE_DEV_CENTER_NAME"

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
environment_type = "production"
cost_center = "ADE-Enterprise"

# Policy configuration
policy_enforcement_mode = "Default"
policy_required_tags = ["Environment", "Owner", "ExpirationDate", "CostCenter"]
policy_allowed_locations = ["$LOCATION", "West US 2", "Central US"]

# Security settings
enable_security_policies = true
require_https_only = true
require_encryption_at_rest = true

# Monitoring settings
enable_monitoring_policies = true
enable_activity_log_alerts = true

# Budget policies
enable_budget_policies = true
max_cost_threshold = 1000

# Additional tags
additional_tags = {
  "DeploymentScript" = "Setup-Complete"
  "DeploymentType" = "Enterprise"
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
        
        # Confirmation prompt (unless force mode)
        if [[ "$FORCE_MODE" == "false" ]]; then
            print_color "$YELLOW" "⚠️ About to deploy complete ADE enterprise solution"
            print_color "$YELLOW" "   This will deploy all three modules:"
            echo "   📊 Budget Governance Module"
            echo "   💬 Slack Integration Module"
            echo "   📋 Policy Governance Module"
            echo
            read -p "Do you want to continue? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                print_color "$YELLOW" "❌ Deployment cancelled by user"
                exit 0
            fi
        fi
        
        # Apply deployment
        print_color "$CYAN" "🚀 Applying complete Terraform deployment..."
        print_color "$YELLOW" "   This will deploy all three modules:"
        echo "   📊 Budget Governance Module"
        echo "   💬 Slack Integration Module"
        echo "   📋 Policy Governance Module"
        
        if ! terraform apply -auto-approve tfplan; then
            print_color "$RED" "❌ Terraform apply failed"
            exit 1
        fi
    fi
    
    print_color "$GREEN" "✅ Complete ADE solution deployed successfully!"
    
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

# Function to create GitHub Actions setup guide
create_github_setup_guide() {
    print_color "$CYAN" "📖 Creating GitHub Actions setup guide..."
    
    local current_subscription current_tenant
    current_subscription=$(az account show --query id -o tsv 2>/dev/null || echo "SUBSCRIPTION_ID")
    current_tenant=$(az account show --query tenantId -o tsv 2>/dev/null || echo "TENANT_ID")
    
    local setup_guide
    setup_guide=$(cat << EOF
# GitHub Actions Setup Guide

## Required Repository Secrets

Configure the following secrets in your GitHub repository (Settings → Secrets and variables → Actions):

\`\`\`
AZURE_CLIENT_ID=YOUR_CLIENT_ID
AZURE_TENANT_ID=$current_tenant
AZURE_SUBSCRIPTION_ID=$current_subscription
ADE_CENTER_NAME=$ADE_DEV_CENTER_NAME
ADE_PROJECT_NAME={YOUR_ADE_PROJECT_NAME}
SLACK_WEBHOOK_URL=$SLACK_WEBHOOK_URL
DEVOPS_TEAM_EMAIL=$DEVOPS_TEAM_EMAIL
FINANCE_TEAM_EMAIL=$FINANCE_TEAM_EMAIL
ADE_RESOURCE_GROUP_NAME=$ADE_RESOURCE_GROUP_NAME
\`\`\`

## Service Principal Setup

Run the following Azure CLI commands to create a service principal for GitHub Actions:

\`\`\`bash
# Create service principal
az ad sp create-for-rbac \\
  --name "sp-ade-github-actions" \\
  --role "Contributor" \\
  --scopes "/subscriptions/$current_subscription" \\
  --sdk-auth

# Grant additional permissions for budget creation
az role assignment create \\
  --assignee \$SERVICE_PRINCIPAL_ID \\
  --role "Cost Management Contributor" \\
  --scope "/subscriptions/$current_subscription"
\`\`\`

## Workflow File

Your workflow file is already configured at:
\`.github/workflows/ade-environment-provisioning.yml\`

## Testing

Test the complete setup by running the workflow with sample parameters:
- Environment Name: test-environment
- Catalog: web-app-catalog
- Expiration Date: $(date -d "+7 days" +%Y-%m-%d 2>/dev/null || date -v+7d +%Y-%m-%d)
- Environment Type: development
- User Email: test@company.com

EOF
)
    
    print_color "$CYAN" "📝 Writing setup guide to GitHub-Actions-Setup.md..."
    if [[ "$WHAT_IF_MODE" == "false" ]]; then
        echo "$setup_guide" > "GitHub-Actions-Setup.md"
        print_color "$GREEN" "✅ Setup guide created: GitHub-Actions-Setup.md"
    else
        print_color "$MAGENTA" "🔍 WhatIf mode - setup guide content:"
        echo "$setup_guide"
    fi
}

# Function to print final summary
print_final_summary() {
    print_color "$GREEN" "🎉 Complete ADE Solution deployed successfully!"
    print_color "$YELLOW" "📋 Deployment Summary:"
    echo "   💰 Budget: \$1000 USD enterprise allocation"
    echo "   🚨 Alert Thresholds: 80%, 95%, 100%, 90% forecast"
    echo "   💬 Slack Integration: Configured with webhook"
    echo "   📋 Governance Policies: Applied with required tags"
    echo "   🔒 Security Policies: HTTPS and encryption required"
    echo "   📊 Monitoring: Activity log alerts enabled"
    echo
    print_color "$YELLOW" "📧 Alert Recipients:"
    echo "   🛠️ DevOps alerts: $DEVOPS_TEAM_EMAIL"
    echo "   💰 Finance alerts: $FINANCE_TEAM_EMAIL"
    echo "   💬 Slack alerts: Configured webhook"
    echo
    print_color "$YELLOW" "🏁 Next Steps:"
    echo "   1. Review GitHub-Actions-Setup.md for GitHub configuration"
    echo "   2. Test Slack webhook integration"
    echo "   3. Verify budget alert functionality"
    echo "   4. Monitor policy compliance"
    echo "   5. Review Application Insights logs"
    echo
    print_color "$CYAN" "📁 Key Files Created:"
    echo "   📖 GitHub-Actions-Setup.md - Complete GitHub Actions setup guide"
    echo "   🏗️ Complete Terraform infrastructure deployed"
    echo
    print_color "$GREEN" "✅ Enterprise ADE solution ready for production use!"
}

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --subscription-id)
                SUBSCRIPTION_ID="$2"
                shift 2
                ;;
            --slack-webhook-url)
                SLACK_WEBHOOK_URL="$2"
                shift 2
                ;;
            --ade-resource-group-name)
                ADE_RESOURCE_GROUP_NAME="$2"
                shift 2
                ;;
            --ade-dev-center-name)
                ADE_DEV_CENTER_NAME="$2"
                shift 2
                ;;
            --integration-resource-group-name)
                INTEGRATION_RESOURCE_GROUP_NAME="$2"
                shift 2
                ;;
            --location)
                LOCATION="$2"
                shift 2
                ;;
            --logic-app-name)
                LOGIC_APP_NAME="$2"
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
            --skip-slack-integration)
                SKIP_SLACK_INTEGRATION=true
                shift
                ;;
            --force)
                FORCE_MODE=true
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
    # Show banner
    show_banner
    
    print_color "$GREEN" "🚀 Starting Complete ADE Enterprise Extensions Setup"
    print_color "$YELLOW" "📋 Script: $SCRIPT_NAME v$SCRIPT_VERSION"
    
    # Parse arguments
    parse_arguments "$@"
    
    # Use environment variables as fallbacks
    SUBSCRIPTION_ID="${SUBSCRIPTION_ID:-${AZURE_SUBSCRIPTION_ID:-}}"
    SLACK_WEBHOOK_URL="${SLACK_WEBHOOK_URL:-${SLACK_WEBHOOK_URL:-}}"
    ADE_RESOURCE_GROUP_NAME="${ADE_RESOURCE_GROUP_NAME:-${ADE_RESOURCE_GROUP_NAME:-}}"
    ADE_DEV_CENTER_NAME="${ADE_DEV_CENTER_NAME:-${ADE_DEV_CENTER_NAME:-}}"
    DEVOPS_TEAM_EMAIL="${DEVOPS_TEAM_EMAIL:-${DEVOPS_TEAM_EMAIL:-$DEFAULT_DEVOPS_TEAM_EMAIL}}"
    FINANCE_TEAM_EMAIL="${FINANCE_TEAM_EMAIL:-${FINANCE_TEAM_EMAIL:-$DEFAULT_FINANCE_TEAM_EMAIL}}"
    
    # Set defaults
    INTEGRATION_RESOURCE_GROUP_NAME="${INTEGRATION_RESOURCE_GROUP_NAME:-$DEFAULT_INTEGRATION_RG_NAME}"
    LOCATION="${LOCATION:-$DEFAULT_LOCATION}"
    LOGIC_APP_NAME="${LOGIC_APP_NAME:-$DEFAULT_LOGIC_APP_NAME}"
    TERRAFORM_PATH="${TERRAFORM_PATH:-$DEFAULT_TERRAFORM_PATH}"
    
    # Validate required parameters
    local missing_params=()
    [[ -z "${SUBSCRIPTION_ID:-}" ]] && missing_params+=("subscription-id")
    [[ -z "${SLACK_WEBHOOK_URL:-}" ]] && missing_params+=("slack-webhook-url")
    [[ -z "${ADE_RESOURCE_GROUP_NAME:-}" ]] && missing_params+=("ade-resource-group-name")
    [[ -z "${ADE_DEV_CENTER_NAME:-}" ]] && missing_params+=("ade-dev-center-name")
    
    if [[ ${#missing_params[@]} -ne 0 ]]; then
        print_color "$RED" "❌ Missing required parameters: ${missing_params[*]}"
        echo
        usage
        exit 1
    fi
    
    # Print configuration summary
    print_color "$YELLOW" "📋 Configuration Summary:"
    echo "   Subscription ID: $SUBSCRIPTION_ID"
    echo "   Integration Resource Group: $INTEGRATION_RESOURCE_GROUP_NAME"
    echo "   Location: $LOCATION"
    echo "   Logic App Name: $LOGIC_APP_NAME"
    echo "   ADE Resource Group: $ADE_RESOURCE_GROUP_NAME"
    echo "   ADE Dev Center: $ADE_DEV_CENTER_NAME"
    echo "   Terraform Path: $TERRAFORM_PATH"
    echo "   DevOps Team Email: $DEVOPS_TEAM_EMAIL"
    echo "   Finance Team Email: $FINANCE_TEAM_EMAIL"
    echo "   What-If Mode: $WHAT_IF_MODE"
    echo "   Force Mode: $FORCE_MODE"
    echo "   Skip Slack Integration: $SKIP_SLACK_INTEGRATION"
    
    # Execute setup steps
    check_prerequisites
    check_azure_auth
    create_integration_resource_group
    validate_ade_resources
    deploy_complete_terraform
    create_github_setup_guide
    print_final_summary
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi