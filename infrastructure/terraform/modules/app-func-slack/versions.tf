# ==============================================================================
# TERRAFORM CONFIGURATION
# Policy Governance Module
# ==============================================================================

terraform {
  required_version = ">= 1.6"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.80"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.4"
    }
  }
}