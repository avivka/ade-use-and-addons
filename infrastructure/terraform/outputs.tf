# ==============================================================================
# OUTPUTS
# Azure Deployment Environments - Budget Governance Infrastructure
# ==============================================================================

# ==============================================================================
# BUDGET INFORMATION
# ==============================================================================

output "budget_name" {
  description = "The name of the consumption budget"
  value       = azurerm_consumption_budget_resource_group.user_budget.name
  sensitive   = false
}

output "budget_id" {
  description = "The ID of the consumption budget"
  value       = azurerm_consumption_budget_resource_group.user_budget.id
  sensitive   = false
}

output "budget_amount" {
  description = "The budget amount configured"
  value       = azurerm_consumption_budget_resource_group.user_budget.amount
  sensitive   = false
}

output "budget_scope" {
  description = "The resource group scope for the budget"
  value       = azurerm_consumption_budget_resource_group.user_budget.resource_group_id
  sensitive   = false
}

# ==============================================================================
# ACTION GROUP INFORMATION
# ==============================================================================

output "action_group_name" {
  description = "The name of the monitor action group"
  value       = azurerm_monitor_action_group.budget_alerts.name
  sensitive   = false
}

output "action_group_id" {
  description = "The ID of the monitor action group"
  value       = azurerm_monitor_action_group.budget_alerts.id
  sensitive   = false
}

output "action_group_short_name" {
  description = "The short name of the action group"
  value       = azurerm_monitor_action_group.budget_alerts.short_name
  sensitive   = false
}

# ==============================================================================
# STORAGE ACCOUNT INFORMATION
# ==============================================================================

output "storage_account_name" {
  description = "The name of the cost monitoring storage account"
  value       = azurerm_storage_account.cost_monitoring.name
  sensitive   = false
}

output "storage_account_id" {
  description = "The ID of the cost monitoring storage account"
  value       = azurerm_storage_account.cost_monitoring.id
  sensitive   = false
}

output "storage_account_primary_endpoint" {
  description = "The primary blob endpoint of the storage account"
  value       = azurerm_storage_account.cost_monitoring.primary_blob_endpoint
  sensitive   = false
}

output "storage_container_name" {
  description = "The name of the cost data storage container"
  value       = azurerm_storage_container.cost_data.name
  sensitive   = false
}

output "storage_container_id" {
  description = "The ID of the cost data storage container"
  value       = azurerm_storage_container.cost_data.id
  sensitive   = false
}

# ==============================================================================
# LOG ANALYTICS INFORMATION
# ==============================================================================

output "log_analytics_workspace_name" {
  description = "The name of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.cost_monitoring.name
  sensitive   = false
}

output "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.cost_monitoring.id
  sensitive   = false
}

output "log_analytics_workspace_workspace_id" {
  description = "The workspace ID of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.cost_monitoring.workspace_id
  sensitive   = true
}

output "log_analytics_primary_shared_key" {
  description = "The primary shared key for the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.cost_monitoring.primary_shared_key
  sensitive   = true
}

# ==============================================================================
# BUDGET NOTIFICATION THRESHOLDS
# ==============================================================================

output "budget_notification_thresholds" {
  description = "The configured budget notification thresholds"
  value = {
    high_usage_alert = "80%"
    critical_alert   = "95%"
    budget_exceeded  = "100%"
    forecast_alert   = "90% (forecast)"
  }
  sensitive = false
}

# ==============================================================================
# RESOURCE IDENTIFIERS
# ==============================================================================

output "resource_group_name" {
  description = "The name of the target resource group"
  value       = data.azurerm_resource_group.target.name
  sensitive   = false
}

output "resource_group_id" {
  description = "The ID of the target resource group"
  value       = data.azurerm_resource_group.target.id
  sensitive   = false
}

output "user_identifier" {
  description = "The user identifier for budget tracking"
  value       = var.user_email
  sensitive   = true
}

output "environment_name" {
  description = "The ADE environment name"
  value       = var.environment_name
  sensitive   = false
}

# ==============================================================================
# DEPLOYMENT INFORMATION
# ==============================================================================

output "deployment_timestamp" {
  description = "The timestamp when this configuration was deployed"
  value       = local.timestamp
  sensitive   = false
}

output "terraform_version" {
  description = "The Terraform version used for deployment"
  value       = "~> 1.6"
  sensitive   = false
}

output "azurerm_provider_version" {
  description = "The Azure Resource Manager provider version"
  value       = "~> 3.80"
  sensitive   = false
}

output "random_suffix" {
  description = "The random suffix used for resource naming"
  value       = random_string.suffix.result
  sensitive   = false
}

# ==============================================================================
# COST TRACKING INFORMATION
# ==============================================================================

output "cost_tracking_configuration" {
  description = "Summary of cost tracking configuration"
  value = {
    budget_amount          = var.budget_amount
    currency              = "USD"
    time_grain            = "Monthly"
    notifications_enabled = true
    alert_thresholds      = ["80%", "95%", "100%", "90% forecast"]
    contact_email         = var.user_email
    devops_team_email     = var.devops_team_email
    retention_days        = var.log_retention_days
  }
  sensitive = false
}

# ==============================================================================
# TAGS APPLIED
# ==============================================================================

output "applied_tags" {
  description = "The tags applied to all resources"
  value       = local.common_tags
  sensitive   = false
}