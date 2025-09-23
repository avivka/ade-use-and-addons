# ==============================================================================
# LOCALS
# Azure Deployment Environments - Budget Governance Local Values
# ==============================================================================

locals {
  # ==============================================================================
  # RESOURCE NAMING
  # ==============================================================================
  
  # Resource naming conventions following Azure best practices
  budget_name        = "budget-user-${var.user_hash}"
  action_group_name  = "ag-budget-${var.user_hash}"
  storage_name       = "stcost${random_string.storage_suffix.result}"
  log_analytics_name = "law-cost-${var.user_hash}"
  container_name     = "cost-data"
  
  # ==============================================================================
  # TAGGING STRATEGY
  # ==============================================================================
  
  # Common tags applied to all resources
  common_tags = merge({
    # Core identification tags
    "purpose"          = "ade-budget-governance"
    "environment"      = var.environment_type
    "cost-center"      = "devops"
    "user-email"       = var.user_email
    "environment-name" = var.environment_name
    "expiration-date"  = var.expiration_date
    "user-hash"        = var.user_hash
    
    # Operational tags
    "managed-by"       = "terraform"
    "created-date"     = formatdate("YYYY-MM-DD", timestamp())
    "deployment-id"    = random_uuid.deployment_id.result
    
    # Compliance tags
    "data-classification" = "internal"
    "backup-required"     = "false"
    "monitoring-required" = "true"
    "budget-tracking"     = "enabled"
    
    # Cost management tags
    "budget-owner"        = var.user_email
    "budget-amount"       = tostring(var.budget_amount)
    "auto-shutdown"       = "enabled"
  }, var.additional_tags)
  
  # ==============================================================================
  # BUDGET NOTIFICATION CONFIGURATION
  # ==============================================================================
  
  # Email recipients for different alert levels
  standard_email_recipients = [
    var.user_email,
    var.devops_team_email
  ]
  
  critical_email_recipients = [
    var.user_email,
    var.devops_team_email,
    var.finance_team_email
  ]
  
  # Budget notification configurations
  budget_notifications = {
    "high-usage-alert" = {
      enabled        = true
      operator       = "GreaterThan"
      threshold      = var.alert_thresholds.high_usage_threshold
      threshold_type = "Actual"
      contact_emails = local.standard_email_recipients
      locale        = "en-US"
    }
    
    "critical-alert" = {
      enabled        = true
      operator       = "GreaterThan"
      threshold      = var.alert_thresholds.critical_threshold
      threshold_type = "Actual"
      contact_emails = local.standard_email_recipients
      locale        = "en-US"
    }
    
    "budget-exceeded" = {
      enabled        = true
      operator       = "GreaterThan"
      threshold      = var.alert_thresholds.budget_exceeded
      threshold_type = "Actual"
      contact_emails = local.critical_email_recipients
      locale        = "en-US"
    }
    
    "forecast-alert" = {
      enabled        = true
      operator       = "GreaterThan"
      threshold      = var.alert_thresholds.forecast_threshold
      threshold_type = "Forecasted"
      contact_emails = local.standard_email_recipients
      locale        = "en-US"
    }
  }
  
  # ==============================================================================
  # SECURITY CONFIGURATION
  # ==============================================================================
  
  # Storage account security settings
  storage_security_config = {
    allow_nested_items_to_be_public = false
    enable_https_traffic_only       = true
    min_tls_version                 = "TLS1_2"
    public_network_access_enabled   = true
    default_action                  = "Allow"
    bypass                         = ["AzureServices"]
  }
  
  # ==============================================================================
  # VALIDATION AND COMPUTED VALUES
  # ==============================================================================
  
  # Current timestamp for tracking deployment and updates
  timestamp = timestamp()
  
  # Validate budget dates
  budget_start_timestamp = timeadd("${var.budget_start_date}T00:00:00Z", "0s")
  budget_end_timestamp   = timeadd("${var.budget_end_date}T23:59:59Z", "0s")
  
  # Environment metadata
  environment_metadata = {
    created_by    = "ade-terraform-module"
    version       = "1.0.0"
    last_updated  = formatdate("YYYY-MM-DD'T'hh:mm:ssZ", timestamp())
    terraform_workspace = terraform.workspace
  }
  
  # Resource group scope for budget
  resource_group_scope = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}"
}