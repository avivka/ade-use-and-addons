# ==============================================================================
# DATA SOURCES
# Policy Governance Module
# ==============================================================================

# Current Azure client configuration
data "azurerm_client_config" "current" {}

# Target resource group (if specified)
data "azurerm_resource_group" "target" {
  count = var.resource_group_name != null ? 1 : 0
  name  = var.resource_group_name
}

# Random string for policy assignment uniqueness
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
  numeric = true
}

# Random UUID for deployment tracking
resource "random_uuid" "deployment_id" {}

# Built-in policy definitions
data "azurerm_policy_definition" "require_tag_and_value" {
  display_name = "Require a tag and its value on resources"
}

data "azurerm_policy_definition" "allowed_locations" {
  display_name = "Allowed locations"
}

data "azurerm_policy_definition" "allowed_resource_types" {
  count        = length(var.allowed_resource_types) > 0 ? 1 : 0
  display_name = "Allowed resource types"
}

data "azurerm_policy_definition" "not_allowed_resource_types" {
  count        = length(var.denied_resource_types) > 0 ? 1 : 0
  display_name = "Not allowed resource types"
}

data "azurerm_policy_definition" "require_https_storage" {
  count        = var.require_https_only ? 1 : 0
  display_name = "Secure transfer to storage accounts should be enabled"
}

data "azurerm_policy_definition" "require_encryption_storage" {
  count        = var.require_encryption_at_rest ? 1 : 0
  display_name = "Storage accounts should use customer-managed key for encryption"
}