# ==============================================================================
# DATA SOURCES
# Logic App Slack Integration Module
# ==============================================================================

# Current Azure client configuration
data "azurerm_client_config" "current" {}

# Target resource group
data "azurerm_resource_group" "target" {
  name = var.resource_group_name
}

# ADE resource group
data "azurerm_resource_group" "ade" {
  name = var.ade_resource_group_name
}

# Random string for resource naming uniqueness
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
  numeric = true
}

# Random UUID for deployment tracking
resource "random_uuid" "deployment_id" {}

# Random string for storage account naming (must be shorter)
resource "random_string" "storage_suffix" {
  length  = 8
  special = false
  upper   = false
  numeric = true
}