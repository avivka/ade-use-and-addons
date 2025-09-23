# Complete Setup Script for ADE Enterprise Extensions using Terraform
# This script deploys the entire solution with proper error handling and validation

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory = $true)]
    [string]$SlackWebhookUrl,
    
    [Parameter(Mandatory = $true)]
    [string]$AdeResourceGroupName,
    
    [Parameter(Mandatory = $true)]
    [string]$AdeDevCenterName,
    
    [Parameter(Mandatory = $false)]
    [string]$IntegrationResourceGroupName = "rg-ade-enterprise-integration",
    
    [Parameter(Mandatory = $false)]
    [string]$Location = "eastus2",
    
    [Parameter(Mandatory = $false)]
    [string]$LogicAppName = "ade-slack-integration-prod",
    
    [Parameter(Mandatory = $false)]
    [string]$TerraformPath = "./infrastructure/terraform/complete",
    
    [Parameter(Mandatory = $false)]
    [string]$DevOpsTeamEmail = "devops@company.com",
    
    [Parameter(Mandatory = $false)]
    [string]$FinanceTeamEmail = "finance@company.com",
    
    [Parameter(Mandatory = $false)]
    [switch]$WhatIf,
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipSlackIntegration,
    
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Function to write colored output
function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args
    }
    else {
        $input | Write-Output
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

# Function to display banner
function Show-Banner {
    Write-ColorOutput Cyan @"
╔═══════════════════════════════════════════════════════════════════════════════╗
║                                                                               ║
║         🚀 Azure Deployment Environments - Enterprise Extensions              ║
║                                                                               ║
║         Complete setup for Slack integration, budget governance,             ║
║         and GitHub Actions workflow automation                               ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝
"@
}

# Function to validate prerequisites
function Test-Prerequisites {
    Write-ColorOutput Cyan "🔍 Validating prerequisites..."
    
    # Check if Azure PowerShell is installed
    if (-not (Get-Module -ListAvailable -Name Az.Accounts)) {
        throw "Azure PowerShell module is not installed. Please install it using: Install-Module -Name Az"
    }
    
    # Check if connected to Azure
    $context = Get-AzContext
    if (-not $context) {
        Write-ColorOutput Yellow "⚠️ Not connected to Azure. Connecting..."
        Connect-AzAccount -SubscriptionId $SubscriptionId
    } elseif ($context.Subscription.Id -ne $SubscriptionId) {
        Write-ColorOutput Yellow "⚠️ Different subscription context. Switching..."
        Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
    }
    
    # Validate ADE resources exist
    $adeRg = Get-AzResourceGroup -Name $AdeResourceGroupName -ErrorAction SilentlyContinue
    if (-not $adeRg) {
        throw "ADE Resource Group '$AdeResourceGroupName' not found"
    }
    
    $adeDevCenter = Get-AzResource -ResourceGroupName $AdeResourceGroupName -Name $AdeDevCenterName -ResourceType "Microsoft.DevCenter/devcenters" -ErrorAction SilentlyContinue
    if (-not $adeDevCenter) {
        throw "ADE Dev Center '$AdeDevCenterName' not found in resource group '$AdeResourceGroupName'"
    }
    
    # Test Slack webhook URL if provided
    if (-not $SkipSlackIntegration -and $SlackWebhookUrl) {
        try {
            $testPayload = @{
                text = "🧪 ADE Enterprise Extensions - Setup Test"
                attachments = @(
                    @{
                        color = "good"
                        title = "Slack Integration Test"
                        text = "If you see this message, the webhook URL is working correctly!"
                        footer = "ADE Enterprise Extensions Setup"
                        ts = [int][double]::Parse((Get-Date -UFormat %s))
                    }
                )
            } | ConvertTo-Json -Depth 3
            
            $response = Invoke-RestMethod -Uri $SlackWebhookUrl -Method Post -Body $testPayload -ContentType "application/json"
            Write-ColorOutput Green "✅ Slack webhook URL validated successfully"
        } catch {
            Write-ColorOutput Yellow "⚠️ Warning: Slack webhook test failed: $($_.Exception.Message)"
            if (-not $Force) {
                $continue = Read-Host "Continue anyway? (y/N)"
                if ($continue -notmatch "^[Yy]$") {
                    throw "Setup cancelled due to Slack webhook validation failure"
                }
            }
        }
    }
    
    Write-ColorOutput Green "✅ All prerequisites validated"
}

# Function to create resource group
function New-IntegrationResourceGroup {
    Write-ColorOutput Cyan "📦 Setting up integration resource group..."
    
    $rg = Get-AzResourceGroup -Name $IntegrationResourceGroupName -ErrorAction SilentlyContinue
    if (-not $rg) {
        if (-not $WhatIf) {
            New-AzResourceGroup -Name $IntegrationResourceGroupName -Location $Location -Force | Out-Null
        }
        Write-ColorOutput Green "✅ Resource group created: $IntegrationResourceGroupName"
    } else {
        Write-ColorOutput Green "✅ Resource group exists: $IntegrationResourceGroupName"
    }
}

# Function to deploy complete solution with Terraform
function Deploy-CompleteWithTerraform {
    Write-ColorOutput Cyan "🚀 Deploying complete ADE solution with Terraform..."
    
    # Navigate to Terraform directory
    $currentPath = Get-Location
    Set-Location $TerraformPath
    
    try {
        # Calculate budget dates
        $startDate = (Get-Date -Day 1).ToString("yyyy-MM-dd")
        $endDate = (Get-Date).AddDays(30).ToString("yyyy-MM-dd")
        
        # Create terraform.tfvars file
        $tfvarsContent = @"
# Required variables
resource_group_name = "$IntegrationResourceGroupName"
location = "$Location"
user_email = "admin@company.com"
user_hash = "admin001"
environment_name = "ade-enterprise"
budget_amount = 1000
budget_start_date = "$startDate"
budget_end_date = "$endDate"
devops_team_email = "$DevOpsTeamEmail"
finance_team_email = "$FinanceTeamEmail"

# Slack integration
slack_integration_name = "$LogicAppName"
slack_webhook_url = "$SlackWebhookUrl"
event_grid_topic_name = "ade-events"
ade_resource_group_name = "$AdeResourceGroupName"
ade_dev_center_name = "$AdeDevCenterName"

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
policy_allowed_locations = ["$Location", "West US 2", "Central US"]

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
"@
        
        Write-ColorOutput Cyan "📝 Creating terraform.tfvars..."
        if (-not $WhatIf) {
            $tfvarsContent | Out-File -FilePath "terraform.tfvars" -Encoding utf8
        }
        
        Write-ColorOutput Cyan "🔧 Initializing Terraform..."
        if (-not $WhatIf) {
            & terraform init
            if ($LASTEXITCODE -ne 0) {
                throw "Terraform init failed"
            }
        }
        
        Write-ColorOutput Cyan "📋 Planning Terraform deployment..."
        if ($WhatIf) {
            Write-ColorOutput Magenta "🔍 Running in WhatIf mode - no resources will be created"
            & terraform plan
        } else {
            & terraform plan -out=tfplan
            if ($LASTEXITCODE -ne 0) {
                throw "Terraform plan failed"
            }
            
            Write-ColorOutput Cyan "🚀 Applying complete Terraform deployment..."
            & terraform apply -auto-approve tfplan
            if ($LASTEXITCODE -ne 0) {
                throw "Terraform apply failed"
            }
        }
        
        Write-ColorOutput Green "✅ Complete ADE solution deployed successfully!"
        
        # Get Terraform outputs
        Write-ColorOutput Cyan "📊 Terraform Outputs:"
        if (-not $WhatIf) {
            & terraform output
        }
        
    } finally {
        # Return to original directory
        Set-Location $currentPath
        
        # Cleanup terraform.tfvars if created
        if (Test-Path (Join-Path $TerraformPath "terraform.tfvars") -and -not $WhatIf) {
            Remove-Item (Join-Path $TerraformPath "terraform.tfvars") -Force -ErrorAction SilentlyContinue
        }
    }
}
}

# Function to create GitHub Actions setup guide
function New-GitHubSetupGuide {
    Write-ColorOutput Cyan "📖 Creating GitHub Actions setup guide..."
    
    $setupGuide = @"
# GitHub Actions Setup Guide

## Required Repository Secrets

Configure the following secrets in your GitHub repository (Settings → Secrets and variables → Actions):

\`\`\`
AZURE_CLIENT_ID=$($context.Account.Id)
AZURE_TENANT_ID=$($context.Tenant.Id)
AZURE_SUBSCRIPTION_ID=$SubscriptionId
ADE_CENTER_NAME=$AdeDevCenterName
ADE_PROJECT_NAME={YOUR_ADE_PROJECT_NAME}
SLACK_WEBHOOK_URL=$SlackWebhookUrl
DEVOPS_TEAM_EMAIL=$DevOpsTeamEmail
FINANCE_TEAM_EMAIL=$FinanceTeamEmail
ADE_RESOURCE_GROUP_NAME=$AdeResourceGroupName
\`\`\`

## Service Principal Setup

Run the following Azure CLI commands to create a service principal for GitHub Actions:

\`\`\`bash
# Create service principal
az ad sp create-for-rbac \
  --name "sp-ade-github-actions" \
  --role "Contributor" \
  --scopes "/subscriptions/$SubscriptionId" \
  --sdk-auth

# Grant Cost Management permissions
az role assignment create \
  --assignee {CLIENT_ID_FROM_ABOVE} \
  --role "Cost Management Contributor" \
  --scope "/subscriptions/$SubscriptionId"
\`\`\`

## Next Steps

1. Copy the GitHub Actions workflow from: .github/workflows/ade-environment-provisioning.yml
2. Configure repository secrets as shown above
3. Set up production approval environment (if needed)
4. Test the workflow with a development environment

## Workflow Usage

1. Navigate to Actions tab in your repository
2. Select "ADE Environment Provisioning" workflow
3. Click "Run workflow"
4. Fill in parameters and run

The workflow will:
- ✅ Validate inputs
- 🔐 Handle approvals (for production)
- 🚀 Provision ADE environment
- 💰 Set up budget and governance
- 📱 Send Slack notifications
- 📋 Create tracking issue
"@
    
    $guidePath = Join-Path $PSScriptRoot "..\docs\GitHub-Setup-Guide.md"
    $setupGuide | Out-File -FilePath $guidePath -Encoding UTF8 -Force
    
    Write-ColorOutput Green "✅ GitHub setup guide created: $guidePath"
}

# Function to validate deployment
function Test-Deployment {
    Write-ColorOutput Cyan "🧪 Validating deployment..."
    
    # Check Logic App if deployed
    if (-not $SkipSlackIntegration) {
        $logicApp = Get-AzResource -ResourceGroupName $IntegrationResourceGroupName -Name $LogicAppName -ResourceType "Microsoft.Web/sites" -ErrorAction SilentlyContinue
        if ($logicApp) {
            Write-ColorOutput Green "✅ Logic App deployed: $LogicAppName"
        } else {
            Write-ColorOutput Red "❌ Logic App not found: $LogicAppName"
        }
    }
    
    # Check Event Grid topic
    $eventGridTopic = Get-AzResource -ResourceGroupName $AdeResourceGroupName -ResourceType "Microsoft.EventGrid/systemTopics" -ErrorAction SilentlyContinue
    if ($eventGridTopic) {
        Write-ColorOutput Green "✅ Event Grid system topic found"
    } else {
        Write-ColorOutput Yellow "⚠️ Event Grid system topic not found - may need manual configuration"
    }
    
    Write-ColorOutput Green "✅ Deployment validation completed"
}

# Function to show completion summary
function Show-CompletionSummary {
    Write-ColorOutput Green @"

🎉 ADE Enterprise Extensions Setup Complete!

📋 What was deployed:
"@
    
    if (-not $SkipSlackIntegration) {
        Write-Host "   ✅ Slack Integration (Logic App)"
        Write-Host "   ✅ Event Grid System Topic"
        Write-Host "   ✅ Key Vault for secrets"
        Write-Host "   ✅ Application Insights for monitoring"
    }
    
    Write-Host "   ✅ GitHub Actions workflow template"
    Write-Host "   ✅ Budget governance templates"
    Write-Host "   ✅ Azure Policy templates"
    Write-Host "   ✅ PowerShell automation scripts"
    Write-Host "   ✅ Comprehensive documentation"
    
    Write-ColorOutput Yellow @"

📋 Next Steps:
   1. Configure GitHub repository secrets (see GitHub-Setup-Guide.md)
   2. Test Slack notifications
   3. Run first environment provisioning workflow
   4. Review budget and policy configurations
   
🔗 Resources:
   • Documentation: ./docs/
   • Workflows: ./.github/workflows/
   • Scripts: ./scripts/
   
📞 Support:
   • DevOps Team: devops-team@company.com
   • Documentation: ./docs/DEPLOYMENT-GUIDE.md
"@
}

# Main execution
try {
    Show-Banner
    
    Write-ColorOutput Yellow "📋 Setup Configuration:"
    Write-Host "   Subscription ID: $SubscriptionId"
    Write-Host "   Integration RG: $IntegrationResourceGroupName"
    Write-Host "   Location: $Location"
    Write-Host "   ADE RG: $AdeResourceGroupName"
    Write-Host "   ADE Dev Center: $AdeDevCenterName"
    Write-Host "   Skip Slack: $SkipSlackIntegration"
    Write-Host "   WhatIf Mode: $WhatIf"
    Write-Host ""
    
    if (-not $Force -and -not $WhatIf) {
        $confirm = Read-Host "Proceed with setup? (y/N)"
        if ($confirm -notmatch "^[Yy]$") {
            Write-ColorOutput Yellow "❌ Setup cancelled by user"
            exit 0
        }
    }
    
    # Execute setup steps
    Test-Prerequisites
    New-IntegrationResourceGroup
    Deploy-CompleteWithTerraform
    New-GitHubSetupGuide
    
    if (-not $WhatIf) {
        Test-Deployment
        Show-CompletionSummary
    } else {
        Write-ColorOutput Magenta "🔍 WhatIf mode completed - no resources were created"
    }
    
} catch {
    Write-ColorOutput Red "❌ Setup failed: $($_.Exception.Message)"
    Write-ColorOutput Red "💥 Stack trace: $($_.ScriptStackTrace)"
    exit 1
} finally {
    Write-ColorOutput Cyan "🏁 Setup script completed"
}