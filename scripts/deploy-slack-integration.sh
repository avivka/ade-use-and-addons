#!/bin/bash

# Bash script for deploying ADE Slack integration infrastructure using Terraform
# This script deploys the complete Logic App solution for Slack notifications
# Compatible with GitHub Actions workflows

set -euo pipefail  # Exit on any error

# Script metadata
SCRIPT_NAME="Deploy-SlackIntegration"
SCRIPT_VERSION="1.0.0"

# Default values
DEFAULT_LOCATION="eastus2"
DEFAULT_LOGIC_APP_NAME="ade-slack-integration"
DEFAULT_TERRAFORM_PATH="./infrastructure/terraform/modules/logic-app-slack"
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

Deploy ADE Slack integration infrastructure using Terraform

Required Arguments:
    --subscription-id SUBSCRIPTION_ID          Azure subscription ID
    --resource-group-name RESOURCE_GROUP       Resource group name
    --slack-webhook-url WEBHOOK_URL             Slack webhook URL
    --ade-resource-group-name ADE_RG            ADE resource group name
    --ade-dev-center-name DEV_CENTER            ADE dev center name

Optional Arguments:
    --location LOCATION                         Azure location (default: $DEFAULT_LOCATION)
    --logic-app-name LOGIC_APP_NAME            Logic app name (default: $DEFAULT_LOGIC_APP_NAME)
    --terraform-path TERRAFORM_PATH            Terraform module path (default: $DEFAULT_TERRAFORM_PATH)
    --what-if                                   Plan only, don't apply changes
    --help                                      Show this help message

Environment Variables (can be used instead of arguments):
    AZURE_SUBSCRIPTION_ID
    ADE_RESOURCE_GROUP_NAME
    ADE_DEV_CENTER_NAME
    SLACK_WEBHOOK_URL

Examples:
    $0 --subscription-id "12345678-1234-1234-1234-123456789012" \\
       --resource-group-name "rg-ade-integration" \\
       --slack-webhook-url "https://hooks.slack.com/services/..." \\
       --ade-resource-group-name "rg-ade-devcenter" \\
       --ade-dev-center-name "dc-company-ade"

    # Using environment variables
    export AZURE_SUBSCRIPTION_ID="12345678-1234-1234-1234-123456789012"
    export SLACK_WEBHOOK_URL="https://hooks.slack.com/services/..."
    $0 --resource-group-name "rg-ade-integration" \\
       --ade-resource-group-name "rg-ade-devcenter" \\
       --ade-dev-center-name "dc-company-ade"

EOF
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
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
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
        print_color "$YELLOW" "⚠️ Resource group '$RESOURCE_GROUP_NAME' does not exist. Creating..."
        if [[ "$WHAT_IF_MODE" == "false" ]]; then
            if ! az group create --name "$RESOURCE_GROUP_NAME" --location "$LOCATION"; then
                print_color "$RED" "❌ Failed to create resource group"
                exit 1
            fi
        fi
        print_color "$GREEN" "✅ Resource group created: $RESOURCE_GROUP_NAME"
    else
        print_color "$GREEN" "✅ Resource group exists: $RESOURCE_GROUP_NAME"
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

# Function to deploy with Terraform
deploy_terraform() {
    print_color "$CYAN" "🚀 Deploying ADE Slack Integration with Terraform..."
    
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
    
    # Create terraform.tfvars file
    local tfvars_content
    tfvars_content=$(cat << EOF
# Required variables
logic_app_name = "$LOGIC_APP_NAME"
location = "$LOCATION"
resource_group_name = "$RESOURCE_GROUP_NAME"
slack_webhook_url = "$SLACK_WEBHOOK_URL"
event_grid_topic_name = "ade-events-topic"
ade_resource_group_name = "$ADE_RESOURCE_GROUP_NAME"
ade_dev_center_name = "$ADE_DEV_CENTER_NAME"

# Optional configuration
environment_type = "production"
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
    
    print_color "$GREEN" "✅ Terraform deployment completed successfully!"
    
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
    print_color "$GREEN" "🎉 ADE Slack Integration deployment completed successfully!"
    print_color "$YELLOW" "📋 Next Steps:"
    echo "   1. Verify Slack webhook configuration in Key Vault"
    echo "   2. Test Event Grid subscription"
    echo "   3. Verify Slack notifications"
    echo "   4. Monitor Application Insights for logs"
}

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --subscription-id)
                SUBSCRIPTION_ID="$2"
                shift 2
                ;;
            --resource-group-name)
                RESOURCE_GROUP_NAME="$2"
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
    print_color "$GREEN" "🚀 Starting ADE Slack Integration Deployment with Terraform"
    print_color "$YELLOW" "📋 Script: $SCRIPT_NAME v$SCRIPT_VERSION"
    
    # Parse arguments
    parse_arguments "$@"
    
    # Use environment variables as fallbacks
    SUBSCRIPTION_ID="${SUBSCRIPTION_ID:-${AZURE_SUBSCRIPTION_ID:-}}"
    ADE_RESOURCE_GROUP_NAME="${ADE_RESOURCE_GROUP_NAME:-${ADE_RESOURCE_GROUP_NAME:-}}"
    ADE_DEV_CENTER_NAME="${ADE_DEV_CENTER_NAME:-${ADE_DEV_CENTER_NAME:-}}"
    SLACK_WEBHOOK_URL="${SLACK_WEBHOOK_URL:-${SLACK_WEBHOOK_URL:-}}"
    
    # Set defaults
    LOCATION="${LOCATION:-$DEFAULT_LOCATION}"
    LOGIC_APP_NAME="${LOGIC_APP_NAME:-$DEFAULT_LOGIC_APP_NAME}"
    TERRAFORM_PATH="${TERRAFORM_PATH:-$DEFAULT_TERRAFORM_PATH}"
    
    # Validate required parameters
    local missing_params=()
    [[ -z "${SUBSCRIPTION_ID:-}" ]] && missing_params+=("subscription-id")
    [[ -z "${RESOURCE_GROUP_NAME:-}" ]] && missing_params+=("resource-group-name")
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
    echo "   Resource Group: $RESOURCE_GROUP_NAME"
    echo "   Location: $LOCATION"
    echo "   Logic App Name: $LOGIC_APP_NAME"
    echo "   ADE Resource Group: $ADE_RESOURCE_GROUP_NAME"
    echo "   ADE Dev Center: $ADE_DEV_CENTER_NAME"
    echo "   Terraform Path: $TERRAFORM_PATH"
    echo "   What-If Mode: $WHAT_IF_MODE"
    
    # Execute deployment steps
    check_prerequisites
    check_azure_auth
    check_resource_group
    validate_ade_resources
    deploy_terraform
    print_summary
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi