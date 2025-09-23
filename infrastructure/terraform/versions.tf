# ==============================================================================
# TERRAFORM CONFIGURATION
# Azure Deployment Environments - Budget Governance Module
# Enterprise-grade budget management with automated alerts
# ==============================================================================

terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.4"
    }
  }

  # Backend configuration - uncomment and configure for production
  # backend "azurerm" {
  #   resource_group_name  = "rg-terraform-state"
  #   storage_account_name = "stterraformstate"
  #   container_name       = "tfstate"
  #   key                  = "ade-budget-governance.tfstate"
  # }
}

# ==============================================================================
# PROVIDER CONFIGURATION
# ==============================================================================

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
    
    log_analytics_workspace {
      permanently_delete_on_destroy = false
    }
  }
}