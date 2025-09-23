# Azure Deployment Environments - Enterprise Extensions Deployment Guide

This guide provides step-by-step instructions for deploying the enterprise-grade extensions for Azure Deployment Environments (ADE).

## 🏗️ Architecture Overview

The solution consists of three main components:

1. **Slack Integration (Logic App)** - Event-driven notifications for ADE lifecycle events
2. **Budget Governance** - Per-user budget allocation and cost management
3. **GitHub Actions Workflow** - Centralized environment provisioning with approval gates

## 📋 Prerequisites

### Azure Prerequisites
- Azure subscription with Owner or Contributor + User Access Administrator roles
- Azure Deployment Environments (ADE) already deployed and configured
- Resource group for the ADE Dev Center
- Azure CLI or Azure PowerShell installed

### GitHub Prerequisites
- GitHub repository with Actions enabled
- GitHub repository secrets configured (see secrets section below)
- Appropriate permissions to run workflows

### Slack Prerequisites
- Slack workspace with admin permissions
- Incoming webhook configured (instructions below)

## 🔐 Required GitHub Secrets

Configure the following secrets in your GitHub repository:

```bash
# Azure Authentication
AZURE_CLIENT_ID          # Service Principal Client ID
AZURE_TENANT_ID          # Azure AD Tenant ID  
AZURE_SUBSCRIPTION_ID    # Azure Subscription ID

# ADE Configuration
ADE_CENTER_NAME          # Name of your ADE Dev Center
ADE_PROJECT_NAME         # Name of your ADE Project

# Slack Integration
SLACK_WEBHOOK_URL        # Slack incoming webhook URL
```

### Setting up Azure Service Principal

```bash
# Create service principal for GitHub Actions
az ad sp create-for-rbac \
  --name "sp-ade-github-actions" \
  --role "Contributor" \
  --scopes "/subscriptions/{subscription-id}" \
  --sdk-auth

# Grant additional permissions for budget management
az role assignment create \
  --assignee {client-id} \
  --role "Cost Management Contributor" \
  --scope "/subscriptions/{subscription-id}"
```

## 🎯 Step 1: Setup Slack Integration

### 1.1 Create Slack Incoming Webhook

1. Go to https://api.slack.com/apps
2. Click "Create New App" → "From scratch"
3. Enter app name: "ADE Notifications"
4. Select your workspace
5. Navigate to "Incoming Webhooks" in the sidebar
6. Activate incoming webhooks
7. Click "Add New Webhook to Workspace"
8. Select the channel for notifications
9. Copy the webhook URL to GitHub secrets

### 1.2 Deploy Logic App Infrastructure

```bash
# Using PowerShell with Terraform
./scripts/Deploy-SlackIntegration.ps1 \
  -SubscriptionId "your-subscription-id" \
  -ResourceGroupName "rg-ade-integration" \
  -SlackWebhookUrl "your-slack-webhook-url" \
  -AdeResourceGroupName "rg-ade-devcenter" \
  -AdeDevCenterName "dc-company-ade" \
  -Location "eastus2"

# Using Terraform directly
cd infrastructure/terraform/modules/logic-app-slack
terraform init
terraform plan -var="slack_webhook_url=your-webhook-url"
terraform apply
```

### 1.3 Verify Logic App Deployment

1. Navigate to the deployed Logic App in Azure Portal
2. Check that the Event Grid system topic is created
3. Verify the Logic App is running and webhook is configured
4. Test the webhook endpoint manually if needed

## 🎯 Step 2: Setup Budget Governance

### 2.1 Understand Budget Allocation

The solution implements per-user budget allocation:
- **$200 USD per user** across all environments
- Automatic budget creation per resource group
- Alert thresholds at 50%, 80%, 90%, and 100%
- Integration with Slack notifications

### 2.2 Deploy Budget Templates

Budget deployment is automatically handled by the GitHub Actions workflow, but you can also deploy manually:

```bash
# Using PowerShell with Terraform
./scripts/Setup-BudgetGovernance.ps1 \
  -SubscriptionId "your-subscription-id" \
  -UserEmail "user@company.com" \
  -EnvironmentName "test-env" \
  -ResourceGroupName "rg-ade-test-env" \
  -BudgetAmount 200 \
  -EnvironmentType "development"

# Using Terraform directly
cd infrastructure/terraform
terraform init
terraform plan -var="user_email=user@company.com" -var="budget_amount=200"
terraform apply
```

### 2.3 Configure Cost Alerts

Cost alerts are automatically configured with the following thresholds:

| Threshold | Type | Recipients | Action |
|-----------|------|------------|--------|
| 80% | Actual | User + DevOps Team | Email notification |
| 95% | Actual | User + DevOps Team | Email + Slack alert |
| 90% | Forecast | User + DevOps Team | Projected overage warning |
| 100% | Actual | User + DevOps + Finance | Budget exceeded alert |

## 🎯 Step 3: Configure GitHub Actions Workflow

### 3.1 Setup Repository Secrets

Configure all required secrets in your GitHub repository:

```bash
# Navigate to your repository
# Go to Settings → Secrets and variables → Actions
# Add the following repository secrets:

AZURE_CLIENT_ID="{your-service-principal-client-id}"
AZURE_TENANT_ID="{your-azure-ad-tenant-id}"
AZURE_SUBSCRIPTION_ID="{your-azure-subscription-id}"
ADE_CENTER_NAME="{your-ade-dev-center-name}"
ADE_PROJECT_NAME="{your-ade-project-name}"
SLACK_WEBHOOK_URL="{your-slack-webhook-url}"
```

### 3.2 Configure Approval Environment

For production environments, set up a protected environment:

1. Go to repository Settings → Environments
2. Create environment named "production-approval"
3. Add required reviewers
4. Configure protection rules
5. Set deployment timeout as needed

### 3.3 Test the Workflow

1. Navigate to Actions tab in your repository
2. Select "ADE Environment Provisioning" workflow
3. Click "Run workflow"
4. Fill in the required parameters:
   - Environment name
   - Catalog selection
   - Expiration date (mandatory)
   - Environment type
   - User email
5. Click "Run workflow"

## 🎯 Step 4: Validation and Testing

### 4.1 Test Slack Notifications

1. Create a test environment using the GitHub workflow
2. Verify Slack messages are received for:
   - Environment created
   - Environment expiring (manually trigger)
   - Environment deleted
   - Deployment failures

### 4.2 Test Budget Alerts

1. Create resources that consume budget
2. Verify email notifications at thresholds
3. Check budget dashboard in Azure Portal
4. Validate cost export data in storage account

### 4.3 Test Policy Enforcement

1. Attempt to create non-compliant resources
2. Verify policy blocking works correctly
3. Check resource tagging is automatically applied
4. Validate VM size restrictions

## 🔧 Troubleshooting

### Common Issues

#### Logic App Not Receiving Events
- Check Event Grid subscription configuration
- Verify Logic App webhook URL is correct
- Check Logic App run history for errors
- Validate Key Vault access permissions

#### Budget Alerts Not Working
- Check Action Group email configuration
- Verify budget scope and filters
- Confirm subscription permissions for Cost Management
- Check email spam folders

#### GitHub Actions Failures
- Verify all repository secrets are configured
- Check Azure service principal permissions
- Validate ADE resource names and locations
- Review workflow logs for specific errors

#### Policy Violations
- Check policy assignment scope
- Verify managed identity permissions
- Review policy definition parameters
- Check Azure Activity Log for policy events

### Debug Commands

```bash
# Check Logic App status
az logicapp show --name "ade-slack-integration" --resource-group "rg-ade-integration"

# List budgets
az consumption budget list --subscription "your-subscription-id"

# Check policy assignments
az policy assignment list --resource-group "rg-ade-test-env"

# View recent deployments
az deployment group list --resource-group "rg-ade-integration" --query "[?provisioningState=='Failed']"
```

## 📊 Monitoring and Maintenance

### Daily Tasks
- Review budget consumption reports
- Check failed workflow runs
- Monitor Slack notification delivery
- Validate environment expiration tracking

### Weekly Tasks
- Review cost trends and anomalies
- Check policy compliance reports
- Update approved resource types if needed
- Review and approve pending environment requests

### Monthly Tasks
- Analyze budget allocation effectiveness
- Update Slack notification templates
- Review and update governance policies
- Archive expired environment data

## 🔄 Updates and Versioning

### Updating Workflow Templates
1. Modify workflow files in `.github/workflows/`
2. Test changes in a development branch
3. Update version tags and changelog
4. Merge to main branch

### Updating Infrastructure
1. Modify Terraform modules in `infrastructure/terraform/`
2. Test deployments in development environment
3. Update variable files and validation rules
4. Deploy to production with approval

### Updating Logic App Workflows
1. Logic App workflows are now managed by Terraform
2. Make changes in the Terraform module
3. Test with sample events using terraform plan
4. Apply changes using terraform apply

## 📞 Support

For issues and questions:
- **DevOps Team**: devops-team@company.com
- **Finance Team**: finance-team@company.com
- **Azure Support**: Create support ticket in Azure Portal
- **GitHub Issues**: Use repository issues for bugs and feature requests

---

**Created with ❤️ for Azure Deployment Environments Enterprise Customers**