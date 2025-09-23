# PowerShell script for deploying ADE Slack integration infrastructure using Terraform
# This script deploys the complete Logic App solution for Slack notifications

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory = $true)]
    [string]$SlackWebhookUrl,
    
    [Parameter(Mandatory = $true)]
    [string]$AdeResourceGroupName,
    
    [Parameter(Mandatory = $true)]
    [string]$AdeDevCenterName,
    
    [Parameter(Mandatory = $false)]
    [string]$Location = "eastus2",
    
    [Parameter(Mandatory = $false)]
    [string]$LogicAppName = "ade-slack-integration",
    
    [Parameter(Mandatory = $false)]
    [string]$TerraformPath = "./infrastructure/terraform/modules/logic-app-slack",
    
    [Parameter(Mandatory = $false)]
    [switch]$WhatIf
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

try {
    Write-ColorOutput Green "🚀 Starting ADE Slack Integration Deployment with Terraform"
    Write-ColorOutput Yellow "📋 Configuration Summary:"
    Write-Host "   Subscription ID: $SubscriptionId"
    Write-Host "   Resource Group: $ResourceGroupName"
    Write-Host "   Location: $Location"
    Write-Host "   Logic App Name: $LogicAppName"
    Write-Host "   ADE Resource Group: $AdeResourceGroupName"
    Write-Host "   ADE Dev Center: $AdeDevCenterName"
    Write-Host "   Terraform Path: $TerraformPath"
    
    # Check if Terraform is installed
    Write-ColorOutput Cyan "🔧 Checking Terraform installation..."
    try {
        $terraformVersion = terraform --version
        Write-ColorOutput Green "✅ Terraform found: $($terraformVersion.Split("`n")[0])"
    } catch {
        throw "Terraform not found. Please install Terraform from https://terraform.io/downloads"
    }
    
    # Connect to Azure if not already connected
    Write-ColorOutput Cyan "🔐 Checking Azure authentication..."
    $context = Get-AzContext
    if (-not $context -or $context.Subscription.Id -ne $SubscriptionId) {
        Write-ColorOutput Yellow "⚠️ Connecting to Azure..."
        Connect-AzAccount -SubscriptionId $SubscriptionId
    }
    
    # Set the subscription context
    Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
    Write-ColorOutput Green "✅ Connected to subscription: $SubscriptionId"
    
    # Check if resource group exists, create if it doesn't
    Write-ColorOutput Cyan "📦 Checking resource group..."
    $rg = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
    if (-not $rg) {
        Write-ColorOutput Yellow "⚠️ Resource group '$ResourceGroupName' does not exist. Creating..."
        if (-not $WhatIf) {
            New-AzResourceGroup -Name $ResourceGroupName -Location $Location -Force | Out-Null
        }
        Write-ColorOutput Green "✅ Resource group created: $ResourceGroupName"
    } else {
        Write-ColorOutput Green "✅ Resource group exists: $ResourceGroupName"
    }
    
    # Validate ADE resources exist
    Write-ColorOutput Cyan "🔍 Validating ADE resources..."
    $adeRg = Get-AzResourceGroup -Name $AdeResourceGroupName -ErrorAction SilentlyContinue
    if (-not $adeRg) {
        throw "ADE Resource Group '$AdeResourceGroupName' not found. Please verify the name."
    }
    
    $adeDevCenter = Get-AzResource -ResourceGroupName $AdeResourceGroupName -Name $AdeDevCenterName -ResourceType "Microsoft.DevCenter/devcenters" -ErrorAction SilentlyContinue
    if (-not $adeDevCenter) {
        throw "ADE Dev Center '$AdeDevCenterName' not found in resource group '$AdeResourceGroupName'. Please verify the name."
    }
    Write-ColorOutput Green "✅ ADE resources validated"
    
    # Check Terraform path
    if (-not (Test-Path $TerraformPath)) {
        throw "Terraform module path not found: $TerraformPath"
    }
    
    # Navigate to Terraform directory
    $currentPath = Get-Location
    Set-Location $TerraformPath
    
    try {
        # Create terraform.tfvars file
        $tfvarsContent = @"
# Required variables
logic_app_name = "$LogicAppName"
location = "$Location"
resource_group_name = "$ResourceGroupName"
slack_webhook_url = "$SlackWebhookUrl"
event_grid_topic_name = "ade-events-topic"
ade_resource_group_name = "$AdeResourceGroupName"
ade_dev_center_name = "$AdeDevCenterName"

# Optional configuration
environment_type = "production"
"@
        
        Write-ColorOutput Cyan "� Creating terraform.tfvars..."
        if (-not $WhatIf) {
            $tfvarsContent | Out-File -FilePath "terraform.tfvars" -Encoding utf8
        }
        
        Write-ColorOutput Cyan "� Initializing Terraform..."
        if (-not $WhatIf) {
            terraform init
            if ($LASTEXITCODE -ne 0) {
                throw "Terraform init failed"
            }
        }
        
        Write-ColorOutput Cyan "📋 Planning Terraform deployment..."
        if ($WhatIf) {
            Write-ColorOutput Magenta "🔍 Running in WhatIf mode - no resources will be created"
            terraform plan
        } else {
            terraform plan -out=tfplan
            if ($LASTEXITCODE -ne 0) {
                throw "Terraform plan failed"
            }
            
            Write-ColorOutput Cyan "🚀 Applying Terraform deployment..."
            terraform apply -auto-approve tfplan
            if ($LASTEXITCODE -ne 0) {
                throw "Terraform apply failed"
            }
        }
        
        Write-ColorOutput Green "✅ Terraform deployment completed successfully!"
        
        # Get Terraform outputs
        Write-ColorOutput Cyan "📊 Terraform Outputs:"
        if (-not $WhatIf) {
            terraform output
        }
        
        Write-ColorOutput Green "🎉 ADE Slack Integration deployment completed successfully!"
        Write-ColorOutput Yellow "� Next Steps:"
        Write-Host "   1. Verify Slack webhook configuration in Key Vault"
        Write-Host "   2. Test Event Grid subscription"
        Write-Host "   3. Verify Slack notifications"
        Write-Host "   4. Monitor Application Insights for logs"
        
    } finally {
        # Return to original directory
        Set-Location $currentPath
    }

} catch {
    Write-ColorOutput Red "❌ Error occurred during deployment:"
    Write-ColorOutput Red $_.Exception.Message
    
    # Return to original directory in case of error
    if ($currentPath) {
        Set-Location $currentPath
    }
    
    exit 1
} finally {
    # Cleanup terraform.tfvars if created
    if (Test-Path (Join-Path $TerraformPath "terraform.tfvars") -and -not $WhatIf) {
        Remove-Item (Join-Path $TerraformPath "terraform.tfvars") -Force -ErrorAction SilentlyContinue
    }
    
    Write-ColorOutput Cyan "🏁 Deployment script completed"
}