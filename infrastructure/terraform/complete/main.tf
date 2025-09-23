# ==============================================================================
# COMPLETE TERRAFORM CONFIGURATION
# Azure Deployment Environments - Enterprise Solution
# ==============================================================================

# This file orchestrates all ADE enterprise capabilities:
# 1. Budget Governance (existing module)
# 2. Logic App Slack Integration (new module)
# 3. Policy Governance (new module)

# ==============================================================================
# TERRAFORM CONFIGURATION
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

# Configure the Azure Provider
provider "azurerm" {
  features {
    key_vault {
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# ==============================================================================
# DATA SOURCES
# ==============================================================================

# Current Azure client configuration
data "azurerm_client_config" "current" {}

# Target resource group
data "azurerm_resource_group" "target" {
  name = var.resource_group_name
}

# ==============================================================================
# BUDGET GOVERNANCE MODULE
# ==============================================================================

module "budget_governance" {
  source = "../"
  
  # Required variables
  resource_group_name = var.resource_group_name
  location           = var.location
  user_email         = var.user_email
  user_hash          = var.user_hash
  environment_name   = var.environment_name
  budget_amount      = var.budget_amount
  budget_start_date  = var.budget_start_date
  budget_end_date    = var.budget_end_date
  devops_team_email  = var.devops_team_email
  finance_team_email = var.finance_team_email
  
  # Alert thresholds
  alert_thresholds = var.alert_thresholds
  
  # Optional configuration
  environment_type            = var.environment_type
  cost_center                = var.cost_center
  expiration_date            = var.expiration_date
  storage_account_tier       = var.storage_account_tier
  storage_replication_type   = var.storage_replication_type
  storage_access_tier        = var.storage_access_tier
  log_analytics_sku          = var.log_analytics_sku
  log_retention_days         = var.log_retention_days
  allow_public_access        = var.allow_public_access
  enable_deletion_protection = var.enable_deletion_protection
  additional_tags            = var.additional_tags
}

# ==============================================================================
# LOGIC APP SLACK INTEGRATION MODULE
# ==============================================================================

module "slack_integration" {
  source = "../modules/logic-app-slack"
  
  # Required variables
  logic_app_name         = var.slack_integration_name
  location              = var.location
  resource_group_name   = var.resource_group_name
  slack_webhook_url     = var.slack_webhook_url
  event_grid_topic_name = var.event_grid_topic_name
  ade_resource_group_name = var.ade_resource_group_name
  ade_dev_center_name   = var.ade_dev_center_name
  
  # Optional configuration
  environment_type                = var.environment_type
  key_vault_sku                  = var.key_vault_sku
  soft_delete_retention_days     = var.soft_delete_retention_days
  storage_account_tier           = var.storage_account_tier
  storage_replication_type       = var.storage_replication_type
  log_analytics_sku              = var.log_analytics_sku
  log_retention_days             = var.log_retention_days
  enable_purge_protection        = var.enable_purge_protection
  enable_rbac_authorization      = var.enable_rbac_authorization
  additional_tags                = var.additional_tags
  
  # Notification settings
  notification_settings = var.notification_settings
  event_filter_settings = var.event_filter_settings
}

# ==============================================================================
# POLICY GOVERNANCE MODULE
# ==============================================================================

module "policy_governance" {
  source = "../modules/policy-governance"
  
  # Required variables
  environment_name = var.environment_name
  user_email      = var.user_email
  expiration_date = var.expiration_date
  environment_type = var.environment_type
  location        = var.location
  
  # Optional variables
  resource_group_name = var.resource_group_name
  cost_center        = var.cost_center
  business_unit      = var.business_unit
  project_code       = var.project_code
  
  # Policy configuration
  enforcement_mode              = var.policy_enforcement_mode
  required_tags                = var.policy_required_tags
  allowed_locations            = var.policy_allowed_locations
  allowed_resource_types       = var.policy_allowed_resource_types
  denied_resource_types        = var.policy_denied_resource_types
  
  # Budget and cost management
  enable_budget_policies = var.enable_budget_policies
  max_cost_threshold    = var.max_cost_threshold
  
  # Security policies
  enable_security_policies     = var.enable_security_policies
  require_https_only          = var.require_https_only
  require_encryption_at_rest  = var.require_encryption_at_rest
  
  # Monitoring and compliance
  enable_monitoring_policies   = var.enable_monitoring_policies
  log_analytics_workspace_id   = module.budget_governance.log_analytics_workspace_id
  enable_activity_log_alerts   = var.enable_activity_log_alerts
  
  # Additional tags
  additional_tags = var.additional_tags
}