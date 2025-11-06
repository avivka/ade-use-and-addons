# ==============================================================================
# OUTPUTS
# Logic App Slack Integration Module
# ==============================================================================

# ==============================================================================
# LOGIC APP INFORMATION
# ==============================================================================

output "logic_app_name" {
  description = "The name of the Logic App Standard"
  value       = azurerm_logic_app_standard.slack_integration.name
  sensitive   = false
}

output "logic_app_id" {
  description = "The ID of the Logic App Standard"
  value       = azurerm_logic_app_standard.slack_integration.id
  sensitive   = false
}

output "logic_app_default_hostname" {
  description = "The default hostname of the Logic App"
  value       = azurerm_logic_app_standard.slack_integration.default_hostname
  sensitive   = false
}

output "logic_app_principal_id" {
  description = "The Principal ID of the Logic App's managed identity"
  value       = azurerm_logic_app_standard.slack_integration.identity[0].principal_id
  sensitive   = false
}

# ==============================================================================
# KEY VAULT INFORMATION
# ==============================================================================

output "key_vault_name" {
  description = "The name of the Key Vault"
  value       = azurerm_key_vault.slack_integration.name
  sensitive   = false
}

output "key_vault_id" {
  description = "The ID of the Key Vault"
  value       = azurerm_key_vault.slack_integration.id
  sensitive   = false
}

output "key_vault_uri" {
  description = "The URI of the Key Vault"
  value       = azurerm_key_vault.slack_integration.vault_uri
  sensitive   = false
}

# ==============================================================================
# STORAGE ACCOUNT INFORMATION
# ==============================================================================

output "storage_account_name" {
  description = "The name of the storage account"
  value       = azurerm_storage_account.slack_integration.name
  sensitive   = false
}

output "storage_account_id" {
  description = "The ID of the storage account"
  value       = azurerm_storage_account.slack_integration.id
  sensitive   = false
}

output "storage_account_primary_endpoint" {
  description = "The primary blob endpoint of the storage account"
  value       = azurerm_storage_account.slack_integration.primary_blob_endpoint
  sensitive   = false
}

# ==============================================================================
# EVENT GRID INFORMATION
# ==============================================================================

output "event_grid_topic_name" {
  description = "The name of the Event Grid system topic"
  value       = azurerm_eventgrid_system_topic.ade_events.name
  sensitive   = false
}

output "event_grid_topic_id" {
  description = "The ID of the Event Grid system topic"
  value       = azurerm_eventgrid_system_topic.ade_events.id
  sensitive   = false
}

output "event_grid_subscription_name" {
  description = "The name of the Event Grid event subscription"
  value       = azurerm_eventgrid_event_subscription.slack_integration.name
  sensitive   = false
}

output "event_grid_subscription_id" {
  description = "The ID of the Event Grid event subscription"
  value       = azurerm_eventgrid_event_subscription.slack_integration.id
  sensitive   = false
}

# ==============================================================================
# APPLICATION INSIGHTS INFORMATION
# ==============================================================================

output "application_insights_name" {
  description = "The name of the Application Insights component"
  value       = azurerm_application_insights.slack_integration.name
  sensitive   = false
}

output "application_insights_id" {
  description = "The ID of the Application Insights component"
  value       = azurerm_application_insights.slack_integration.id
  sensitive   = false
}

output "application_insights_instrumentation_key" {
  description = "The instrumentation key of Application Insights"
  value       = azurerm_application_insights.slack_integration.instrumentation_key
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "The connection string of Application Insights"
  value       = azurerm_application_insights.slack_integration.connection_string
  sensitive   = true
}

# ==============================================================================
# LOG ANALYTICS INFORMATION
# ==============================================================================

output "log_analytics_workspace_name" {
  description = "The name of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.slack_integration.name
  sensitive   = false
}

output "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.slack_integration.id
  sensitive   = false
}

output "log_analytics_workspace_workspace_id" {
  description = "The workspace ID of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.slack_integration.workspace_id
  sensitive   = true
}

# ==============================================================================
# SERVICE PLAN INFORMATION
# ==============================================================================

output "service_plan_name" {
  description = "The name of the App Service Plan"
  value       = azurerm_service_plan.slack_integration.name
  sensitive   = false
}

output "service_plan_id" {
  description = "The ID of the App Service Plan"
  value       = azurerm_service_plan.slack_integration.id
  sensitive   = false
}

# ==============================================================================
# INTEGRATION ENDPOINTS
# ==============================================================================

output "webhook_endpoint_url" {
  description = "The webhook endpoint URL for Event Grid integration"
  value       = "https://${azurerm_logic_app_standard.slack_integration.default_hostname}/runtime/webhooks/workflow/api/management/workflows/ade-slack-notification/triggers/manual/listCallbackUrl"
  sensitive   = false
}

output "slack_integration_status" {
  description = "Status information about the Slack integration setup"
  value = {
    logic_app_ready       = true
    key_vault_configured  = true
    event_grid_configured = true
    storage_configured    = true
    monitoring_enabled    = true
  }
  sensitive = false
}

# ==============================================================================
# RESOURCE IDENTIFIERS
# ==============================================================================

output "resource_group_name" {
  description = "The name of the resource group"
  value       = var.resource_group_name
  sensitive   = false
}

output "location" {
  description = "The Azure region where resources are deployed"
  value       = var.location
  sensitive   = false
}

output "deployment_timestamp" {
  description = "The timestamp when this module was deployed"
  value       = local.timestamp
  sensitive   = false
}

output "random_suffix" {
  description = "The random suffix used for resource naming"
  value       = local.random_suffix
  sensitive   = false
}

# ==============================================================================
# CONFIGURATION SUMMARY
# ==============================================================================

output "slack_integration_configuration" {
  description = "Summary of the Slack integration configuration"
  value = {
    logic_app_name          = azurerm_logic_app_standard.slack_integration.name
    event_grid_topic        = azurerm_eventgrid_system_topic.ade_events.name
    key_vault_name          = azurerm_key_vault.slack_integration.name
    storage_account_name    = azurerm_storage_account.slack_integration.name
    ade_resource_group      = var.ade_resource_group_name
    ade_dev_center         = var.ade_dev_center_name
    notification_settings   = var.notification_settings
    event_filter_settings   = var.event_filter_settings
    environment_type        = var.environment_type
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