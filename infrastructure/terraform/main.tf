# ==============================================================================
# MAIN CONFIGURATION
# Azure Deployment Environments - Budget Governance Infrastructure
# ==============================================================================

# ==============================================================================
# ACTION GROUP FOR BUDGET ALERTS
# ==============================================================================

resource "azurerm_monitor_action_group" "budget_alerts" {
  name                = local.action_group_name
  resource_group_name = var.resource_group_name
  short_name          = "BudgetAlert"
  enabled             = true
  tags                = local.common_tags

  # Email notifications for budget owner
  email_receiver {
    name                    = "BudgetOwner"
    email_address          = var.user_email
    use_common_alert_schema = true
  }

  # Email notifications for DevOps team
  email_receiver {
    name                    = "DevOpsTeam"
    email_address          = var.devops_team_email
    use_common_alert_schema = true
  }

  # Optional: Add webhook receiver for Slack integration
  # webhook_receiver {
  #   name        = "SlackWebhook"
  #   service_uri = var.slack_webhook_url
  #   use_common_alert_schema = true
  # }

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      tags["created-date"],
      tags["last_updated"]
    ]
  }
}

# ==============================================================================
# CONSUMPTION BUDGET WITH NOTIFICATIONS
# ==============================================================================

resource "azurerm_consumption_budget_resource_group" "user_budget" {
  name              = local.budget_name
  resource_group_id = data.azurerm_resource_group.target.id

  amount     = var.budget_amount
  time_grain = "Monthly"

  time_period {
    start_date = var.budget_start_date
    end_date   = var.budget_end_date
  }

  # High usage threshold notification (80%)
  notification {
    enabled        = local.budget_notifications["high-usage-alert"].enabled
    threshold      = local.budget_notifications["high-usage-alert"].threshold
    operator       = local.budget_notifications["high-usage-alert"].operator
    threshold_type = local.budget_notifications["high-usage-alert"].threshold_type
    
    contact_emails = local.budget_notifications["high-usage-alert"].contact_emails
    
    contact_groups = [
      azurerm_monitor_action_group.budget_alerts.id
    ]
  }

  # Critical threshold notification (95%)
  notification {
    enabled        = local.budget_notifications["critical-alert"].enabled
    threshold      = local.budget_notifications["critical-alert"].threshold
    operator       = local.budget_notifications["critical-alert"].operator
    threshold_type = local.budget_notifications["critical-alert"].threshold_type
    
    contact_emails = local.budget_notifications["critical-alert"].contact_emails
    
    contact_groups = [
      azurerm_monitor_action_group.budget_alerts.id
    ]
  }

  # Budget exceeded notification (100%)
  notification {
    enabled        = local.budget_notifications["budget-exceeded"].enabled
    threshold      = local.budget_notifications["budget-exceeded"].threshold
    operator       = local.budget_notifications["budget-exceeded"].operator
    threshold_type = local.budget_notifications["budget-exceeded"].threshold_type
    
    contact_emails = local.budget_notifications["budget-exceeded"].contact_emails
    
    contact_groups = [
      azurerm_monitor_action_group.budget_alerts.id
    ]
  }

  # Forecasted overage notification (90%)
  notification {
    enabled        = local.budget_notifications["forecast-alert"].enabled
    threshold      = local.budget_notifications["forecast-alert"].threshold
    operator       = local.budget_notifications["forecast-alert"].operator
    threshold_type = local.budget_notifications["forecast-alert"].threshold_type
    
    contact_emails = local.budget_notifications["forecast-alert"].contact_emails
    
    contact_groups = [
      azurerm_monitor_action_group.budget_alerts.id
    ]
  }

  # Filter budget to this specific resource group
  filter {
    dimension {
      name   = "ResourceGroupName"
      values = [data.azurerm_resource_group.target.name]
    }
  }

  lifecycle {
    create_before_destroy = false
    prevent_destroy       = var.enable_deletion_protection
  }

  depends_on = [
    azurerm_monitor_action_group.budget_alerts
  ]
}

# ==============================================================================
# STORAGE ACCOUNT FOR COST MONITORING DATA
# ==============================================================================

resource "azurerm_storage_account" "cost_monitoring" {
  name                = local.storage_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = local.common_tags

  # Performance and replication configuration
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_replication_type
  account_kind            = "StorageV2"
  access_tier             = var.storage_access_tier

  # Security configuration
  allow_nested_items_to_be_public = local.storage_security_config.allow_nested_items_to_be_public
  https_traffic_only_enabled      = local.storage_security_config.enable_https_traffic_only
  min_tls_version                 = local.storage_security_config.min_tls_version
  public_network_access_enabled   = local.storage_security_config.public_network_access_enabled

  # Network access rules
  network_rules {
    default_action = local.storage_security_config.default_action
    bypass         = local.storage_security_config.bypass
  }

  # Blob encryption configuration
  blob_properties {
    delete_retention_policy {
      days = 30
    }
    
    container_delete_retention_policy {
      days = 30
    }
    
    versioning_enabled = true
    
    change_feed_enabled = false
  }

  lifecycle {
    create_before_destroy = true
    prevent_destroy       = var.enable_deletion_protection
    ignore_changes = [
      tags["created-date"],
      tags["last_updated"]
    ]
  }
}

# ==============================================================================
# STORAGE CONTAINER FOR COST DATA
# ==============================================================================

resource "azurerm_storage_container" "cost_data" {
  name                 = local.container_name
  storage_account_id   = azurerm_storage_account.cost_monitoring.id
  container_access_type = "private"

  metadata = {
    purpose          = "ade-cost-tracking"
    user_email       = var.user_email
    environment_name = var.environment_name
    created_by       = "terraform"
  }

  lifecycle {
    prevent_destroy = var.enable_deletion_protection
  }

  depends_on = [
    azurerm_storage_account.cost_monitoring
  ]
}

# ==============================================================================
# LOG ANALYTICS WORKSPACE FOR COST MONITORING
# ==============================================================================

resource "azurerm_log_analytics_workspace" "cost_monitoring" {
  name                = local.log_analytics_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = local.common_tags

  # Pricing and retention configuration
  sku               = var.log_analytics_sku
  retention_in_days = var.log_retention_days

  # Access control configuration
  internet_ingestion_enabled = true
  internet_query_enabled     = true

  lifecycle {
    create_before_destroy = true
    prevent_destroy       = var.enable_deletion_protection
    ignore_changes = [
      tags["created-date"],
      tags["last_updated"]
    ]
  }
}

# ==============================================================================
# DIAGNOSTIC SETTINGS FOR COST MONITORING
# ==============================================================================

# Enable diagnostic settings for the storage account
resource "azurerm_monitor_diagnostic_setting" "storage_diagnostics" {
  name                       = "storage-diagnostics"
  target_resource_id         = azurerm_storage_account.cost_monitoring.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.cost_monitoring.id

  enabled_log {
    category = "StorageRead"
  }

  enabled_log {
    category = "StorageWrite"
  }

  enabled_log {
    category = "StorageDelete"
  }

  # Note: Use enabled_log for metrics in newer provider versions
  enabled_log {
    category = "Transaction"
  }

  enabled_log {
    category = "Capacity"
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    azurerm_storage_account.cost_monitoring,
    azurerm_log_analytics_workspace.cost_monitoring
  ]
}