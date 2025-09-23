# ==============================================================================
# DATA SOURCES
# Azure Deployment Environments - Budget Governance Data Sources
# ==============================================================================

# ==============================================================================
# AZURE CLIENT CONFIGURATION
# ==============================================================================

# Get current Azure client configuration
data "azurerm_client_config" "current" {
  # No configuration required - provides current Azure context
}

# ==============================================================================
# RESOURCE GROUP INFORMATION
# ==============================================================================

# Get information about the target resource group
data "azurerm_resource_group" "target" {
  name = var.resource_group_name
}

# ==============================================================================
# SUBSCRIPTION INFORMATION
# ==============================================================================

# Get current subscription details for budget scope
data "azurerm_subscription" "current" {
  # No configuration required - provides current subscription details
}

# ==============================================================================
# EXISTING BUDGETS VALIDATION
# ==============================================================================

# Query existing budgets to prevent conflicts and validate user allocation
# Note: This requires custom data source or external data source
# Implementation depends on specific requirements for budget conflict detection

# ==============================================================================
# LOCATION VALIDATION
# ==============================================================================

# Validate that the specified location supports required services
data "azurerm_locations" "available" {
  # No configuration required - provides list of available locations
}

# ==============================================================================
# RANDOM RESOURCES FOR UNIQUE NAMING
# ==============================================================================

# Generate unique suffix for storage account name
resource "random_string" "storage_suffix" {
  length  = 8
  special = false
  upper   = false
  numeric = true
  lower   = true
}

# Generate unique deployment ID for tracking
resource "random_uuid" "deployment_id" {
  # No configuration required - generates random UUID
}