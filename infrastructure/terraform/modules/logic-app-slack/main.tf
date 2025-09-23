# ==============================================================================
# MAIN CONFIGURATION
# Logic App Slack Integration Module
# ==============================================================================

# ==============================================================================
# KEY VAULT FOR SECURE STORAGE
# ==============================================================================

resource "azurerm_key_vault" "slack_integration" {
  name                = local.key_vault_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  tags                = local.common_tags

  # Configuration
  sku_name = var.key_vault_sku

  # Security settings  
  enabled_for_deployment          = false
  enabled_for_disk_encryption     = false
  enabled_for_template_deployment = true

  # Soft delete and purge protection
  soft_delete_retention_days = local.key_vault_security_config.soft_delete_retention
  purge_protection_enabled   = local.key_vault_security_config.enable_purge_protection

  # Network access rules
  network_acls {
    default_action = local.key_vault_security_config.default_action
    bypass         = local.key_vault_security_config.bypass
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      tags["created-date"]
    ]
  }
}

# ==============================================================================
# KEY VAULT SECRETS
# ==============================================================================

resource "azurerm_key_vault_secret" "slack_webhook_url" {
  name         = local.secret_names.slack_webhook
  value        = var.slack_webhook_url
  key_vault_id = azurerm_key_vault.slack_integration.id
  tags         = local.common_tags

  content_type = "text/plain"

  lifecycle {
    ignore_changes = [
      tags["created-date"]
    ]
  }

  depends_on = [
    azurerm_key_vault.slack_integration
  ]
}

# ==============================================================================
# LOG ANALYTICS WORKSPACE
# ==============================================================================

resource "azurerm_log_analytics_workspace" "slack_integration" {
  name                = local.log_analytics_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = local.common_tags

  sku               = var.log_analytics_sku
  retention_in_days = var.log_retention_days

  # Access control
  internet_ingestion_enabled = true
  internet_query_enabled     = true

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      tags["created-date"]
    ]
  }
}

# ==============================================================================
# APPLICATION INSIGHTS
# ==============================================================================

resource "azurerm_application_insights" "slack_integration" {
  name                = local.app_insights_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = local.common_tags

  application_type                = local.app_insights_config.application_type
  workspace_id                   = azurerm_log_analytics_workspace.slack_integration.id
  retention_in_days             = local.app_insights_config.retention_in_days
  daily_data_cap_in_gb          = local.app_insights_config.daily_data_cap_in_gb
  daily_data_cap_notifications_disabled = local.app_insights_config.daily_data_cap_notifications_disabled
  sampling_percentage           = local.app_insights_config.sampling_percentage
  disable_ip_masking           = local.app_insights_config.disable_ip_masking

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      tags["created-date"]
    ]
  }

  depends_on = [
    azurerm_log_analytics_workspace.slack_integration
  ]
}

# ==============================================================================
# STORAGE ACCOUNT FOR LOGIC APP
# ==============================================================================

resource "azurerm_storage_account" "slack_integration" {
  name                = local.storage_account_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = local.common_tags

  # Performance and replication
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_replication_type
  account_kind            = "StorageV2"
  access_tier             = "Hot"

  # Security configuration
  allow_nested_items_to_be_public = local.storage_security_config.allow_nested_items_to_be_public
  https_traffic_only_enabled      = local.storage_security_config.https_traffic_only_enabled
  min_tls_version                 = local.storage_security_config.min_tls_version
  public_network_access_enabled   = local.storage_security_config.public_network_access_enabled

  # Network access rules
  network_rules {
    default_action = local.storage_security_config.default_action
    bypass         = local.storage_security_config.bypass
  }

  # Blob properties
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
    ignore_changes = [
      tags["created-date"]
    ]
  }
}

# ==============================================================================
# STORAGE ACCOUNT KEY VAULT SECRET
# ==============================================================================

resource "azurerm_key_vault_secret" "storage_connection_string" {
  name         = local.secret_names.storage_key
  value        = azurerm_storage_account.slack_integration.primary_connection_string
  key_vault_id = azurerm_key_vault.slack_integration.id
  tags         = local.common_tags

  content_type = "connection-string"

  lifecycle {
    ignore_changes = [
      tags["created-date"]
    ]
  }

  depends_on = [
    azurerm_key_vault.slack_integration,
    azurerm_storage_account.slack_integration
  ]
}

# ==============================================================================
# SERVICE PLAN FOR LOGIC APP STANDARD
# ==============================================================================

resource "azurerm_service_plan" "slack_integration" {
  name                = local.service_plan_name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = local.common_tags

  os_type  = local.service_plan_config.os_type
  sku_name = local.service_plan_config.sku_name

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      tags["created-date"]
    ]
  }
}

# ==============================================================================
# LOGIC APP STANDARD (NEW ARCHITECTURE)
# ==============================================================================

resource "azurerm_logic_app_standard" "slack_integration" {
  name                       = local.logic_app_standard_name
  location                   = var.location
  resource_group_name        = var.resource_group_name
  app_service_plan_id       = azurerm_service_plan.slack_integration.id
  storage_account_name      = azurerm_storage_account.slack_integration.name
  storage_account_access_key = azurerm_storage_account.slack_integration.primary_access_key
  tags                      = local.common_tags

  # Application settings
  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME"              = "node"
    "WEBSITE_NODE_DEFAULT_VERSION"          = "~18"
    "AzureWebJobsDisableHomepage"          = "true"
    "APPINSIGHTS_INSTRUMENTATIONKEY"       = azurerm_application_insights.slack_integration.instrumentation_key
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.slack_integration.connection_string
    
    # Key Vault references
    "SLACK_WEBHOOK_URL" = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.slack_webhook_url.versionless_id})"
    
    # Event Grid configuration
    "EVENT_GRID_TOPIC_ENDPOINT" = "https://${local.event_grid_topic_name}.${var.location}-1.eventgrid.azure.net/api/events"
    "ADE_RESOURCE_GROUP_NAME"   = var.ade_resource_group_name
    "ADE_DEV_CENTER_NAME"       = var.ade_dev_center_name
    
    # Notification settings
    "NOTIFICATION_CHANNEL_PREFIX"    = var.notification_settings.channel_prefix
    "NOTIFICATION_MENTION_USERS"     = tostring(var.notification_settings.mention_users)
    "NOTIFICATION_INCLUDE_COST_INFO" = tostring(var.notification_settings.include_cost_info)
    "NOTIFICATION_TIMEZONE"          = var.notification_settings.timezone
    "NOTIFICATION_RETRY_ATTEMPTS"    = tostring(var.notification_settings.retry_attempts)
    
    # Event filtering
    "EVENT_FILTER_ENVIRONMENT_TYPES" = join(",", var.event_filter_settings.environment_types)
    "EVENT_FILTER_COST_THRESHOLD"    = tostring(var.event_filter_settings.cost_threshold)
    "EVENT_FILTER_CRITICAL_EVENTS"   = join(",", var.event_filter_settings.critical_events)
  }

  # Site configuration
  site_config {
    always_on                 = true
    use_32_bit_worker_process = false
  }

  # Identity for Key Vault access
  identity {
    type = "SystemAssigned"
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      tags["created-date"],
      app_settings["AzureWebJobsSecretStorageType"]
    ]
  }

  depends_on = [
    azurerm_service_plan.slack_integration,
    azurerm_storage_account.slack_integration,
    azurerm_application_insights.slack_integration,
    azurerm_key_vault_secret.slack_webhook_url
  ]
}

# ==============================================================================
# EVENT GRID SYSTEM TOPIC
# ==============================================================================

resource "azurerm_eventgrid_system_topic" "ade_events" {
  name                = local.event_grid_topic_name
  location            = var.location
  resource_group_name = var.resource_group_name
  topic_type         = "Microsoft.Resources.ResourceGroups"
  identity {
    type = "SystemAssigned"
  }
  tags = local.common_tags

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      tags["created-date"]
    ]
  }
}

# ==============================================================================
# EVENT GRID EVENT SUBSCRIPTION
# ==============================================================================

resource "azurerm_eventgrid_event_subscription" "slack_integration" {
  name  = "ade-slack-subscription"
  scope = azurerm_eventgrid_system_topic.ade_events.id

  # Webhook endpoint pointing to Logic App
  webhook_endpoint {
    url = "https://${azurerm_logic_app_standard.slack_integration.default_hostname}/runtime/webhooks/workflow/api/management/workflows/ade-slack-notification/triggers/manual/listCallbackUrl?api-version=2020-05-01-preview&code=${azurerm_logic_app_standard.slack_integration.id}"
  }

  # Event filtering
  included_event_types = local.event_subscription_config.included_event_types

  subject_filter {
    subject_begins_with = join("", local.event_subscription_config.subject_filters.begins_with)
    subject_ends_with   = join("", local.event_subscription_config.subject_filters.ends_with)
    case_sensitive      = false
  }

  # Advanced filtering
  dynamic "advanced_filter" {
    for_each = local.event_subscription_config.advanced_filters
    content {
      string_in {
        key    = advanced_filter.value.key
        values = advanced_filter.value.values
      }
    }
  }

  # Retry policy
  retry_policy {
    max_delivery_attempts = 30
    event_time_to_live    = 1440
  }

  # Dead letter destination
  storage_blob_dead_letter_destination {
    storage_account_id          = azurerm_storage_account.slack_integration.id
    storage_blob_container_name = "deadletter"
  }

  depends_on = [
    azurerm_eventgrid_system_topic.ade_events,
    azurerm_logic_app_standard.slack_integration,
    azurerm_storage_account.slack_integration
  ]
}

# ==============================================================================
# STORAGE CONTAINER FOR DEAD LETTER
# ==============================================================================

resource "azurerm_storage_container" "deadletter" {
  name                 = "deadletter"
  storage_account_id   = azurerm_storage_account.slack_integration.id
  container_access_type = "private"

  metadata = {
    purpose = "event-grid-dead-letter"
  }

  depends_on = [
    azurerm_storage_account.slack_integration
  ]
}

# ==============================================================================
# KEY VAULT ACCESS POLICY FOR LOGIC APP
# ==============================================================================

resource "azurerm_key_vault_access_policy" "logic_app_access" {
  key_vault_id = azurerm_key_vault.slack_integration.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_logic_app_standard.slack_integration.identity[0].principal_id

  secret_permissions = [
    "Get",
    "List"
  ]

  depends_on = [
    azurerm_key_vault.slack_integration,
    azurerm_logic_app_standard.slack_integration
  ]
}

# ==============================================================================
# DIAGNOSTIC SETTINGS
# ==============================================================================

resource "azurerm_monitor_diagnostic_setting" "logic_app_diagnostics" {
  name                       = "logic-app-diagnostics"
  target_resource_id         = azurerm_logic_app_standard.slack_integration.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.slack_integration.id

  enabled_log {
    category = "WorkflowRuntime"
  }

  enabled_log {
    category = "FunctionAppLogs"
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    azurerm_logic_app_standard.slack_integration,
    azurerm_log_analytics_workspace.slack_integration
  ]
}