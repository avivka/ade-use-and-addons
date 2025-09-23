# PowerShell script for setting up budget governance for ADE users using Terraform
# This script creates and manages per-user budget allocations

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory = $true)]
    [string]$UserEmail,
    
    [Parameter(Mandatory = $true)]
    [string]$EnvironmentName,
    
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory = $false)]
    [int]$BudgetAmount = 200,
    
    [Parameter(Mandatory = $false)]
    [string]$EnvironmentType = "development",
    
    [Parameter(Mandatory = $false)]
    [string]$ExpirationDate = (Get-Date).AddDays(30).ToString("yyyy-MM-dd"),
    
    [Parameter(Mandatory = $false)]
    [string]$Location = "eastus2",
    
    [Parameter(Mandatory = $false)]
    [string]$TerraformPath = "./infrastructure/terraform",
    
    [Parameter(Mandatory = $false)]
    [string]$DevOpsTeamEmail = "devops@company.com",
    
    [Parameter(Mandatory = $false)]
    [string]$FinanceTeamEmail = "finance@company.com",
    
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

# Function to generate user hash
function Get-UserHash {
    param([string]$Email)
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Email.ToLower())
    $hash = $sha256.ComputeHash($bytes)
    $hashString = [System.BitConverter]::ToString($hash).Replace("-", "").ToLower()
    return $hashString.Substring(0, 8)
}

try {
    Write-ColorOutput Green "💰 Starting ADE Budget Governance Setup with Terraform"
    Write-ColorOutput Yellow "📋 Configuration Summary:"
    Write-Host "   Subscription ID: $SubscriptionId"
    Write-Host "   User Email: $UserEmail"
    Write-Host "   Environment Name: $EnvironmentName"
    Write-Host "   Resource Group: $ResourceGroupName"
    Write-Host "   Budget Amount: $$$BudgetAmount USD"
    Write-Host "   Environment Type: $EnvironmentType"
    Write-Host "   Expiration Date: $ExpirationDate"
    Write-Host "   Location: $Location"
    Write-Host "   Terraform Path: $TerraformPath"
    
    # Generate user hash for unique naming
    $userHash = Get-UserHash -Email $UserEmail
    Write-Host "   User Hash: $userHash"
    
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
    
    # Check if resource group exists
    Write-ColorOutput Cyan "📦 Checking resource group..."
    $rg = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
    if (-not $rg) {
        throw "Resource group '$ResourceGroupName' does not exist. Please create it first or run the main environment provisioning workflow."
    }
    Write-ColorOutput Green "✅ Resource group found: $ResourceGroupName"
    
    # Check Terraform path
    if (-not (Test-Path $TerraformPath)) {
        throw "Terraform module path not found: $TerraformPath"
    }
    
    # Navigate to Terraform directory
    $currentPath = Get-Location
    Set-Location $TerraformPath
    
    try {
        # Calculate budget dates
        $startDate = (Get-Date -Day 1).ToString("yyyy-MM-dd")
        $endDate = $ExpirationDate
        
        # Create terraform.tfvars file
        $tfvarsContent = @"
# Required variables
resource_group_name = "$ResourceGroupName"
location = "$Location"
user_email = "$UserEmail"
user_hash = "$userHash"
environment_name = "$EnvironmentName"
budget_amount = $BudgetAmount
budget_start_date = "$startDate"
budget_end_date = "$endDate"
devops_team_email = "$DevOpsTeamEmail"
finance_team_email = "$FinanceTeamEmail"

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
environment_type = "$EnvironmentType"
expiration_date = "$ExpirationDate"
cost_center = "ADE-Environments"

# Additional tags
additional_tags = {
  "PowerShellScript" = "Setup-BudgetGovernance"
  "UserHash" = "$userHash"
}
"@
        
        Write-ColorOutput Cyan "📝 Creating terraform.tfvars..."
        if (-not $WhatIf) {
            $tfvarsContent | Out-File -FilePath "terraform.tfvars" -Encoding utf8
        }
        
        Write-ColorOutput Cyan "🔧 Initializing Terraform..."
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
        
        Write-ColorOutput Green "✅ Budget governance setup completed successfully!"
        
        # Get Terraform outputs
        Write-ColorOutput Cyan "📊 Terraform Outputs:"
        if (-not $WhatIf) {
            terraform output
        }
        
        Write-ColorOutput Green "🎉 ADE Budget Governance setup completed successfully!"
        Write-ColorOutput Yellow "📋 Budget Configuration:"
        Write-Host "   💰 Budget Amount: $$$BudgetAmount USD"
        Write-Host "   📅 Start Date: $startDate"
        Write-Host "   📅 End Date: $endDate"
        Write-Host "   🚨 Alert Thresholds: 80%, 95%, 100%, 90% forecast"
        Write-Host "   👤 User: $UserEmail ($userHash)"
        
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
    
    Write-ColorOutput Cyan "🏁 Budget governance script completed"
}