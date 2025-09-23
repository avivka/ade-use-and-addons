# ==============================================================================
# VARIABLES
# Azure Deployment Environments - Complete Enterprise Solution
# ==============================================================================

# ==============================================================================
# REQUIRED VARIABLES
# ==============================================================================

variable "resource_group_name" {
  description = "The name of the resource group where all resources will be deployed"
  type        = string
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9-._\\(\\)]{1,90}$", var.resource_group_name))
    error_message = "Resource group name must be 1-90 characters and can contain alphanumeric, underscore, parentheses, hyphen, and period characters."
  }
}

variable "location" {
  description = "The Azure region where resources will be created"
  type        = string
  
  validation {
    condition = contains([
      "eastus", "eastus2", "westus", "westus2", "westus3", "centralus", "northcentralus", "southcentralus",
      "northeurope", "westeurope", "japaneast", "japanwest", "eastasia", "southeastasia",
      "australiaeast", "australiasoutheast", "brazilsouth", "canadacentral", "canadaeast",
      "uksouth", "ukwest", "francecentral", "germanywestcentral", "norwayeast", "switzerlandnorth"
    ], var.location)
    error_message = "Location must be a valid Azure region."
  }
}

variable "user_email" {
  description = "User email for notifications and tagging"
  type        = string
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.user_email))
    error_message = "User email must be a valid email address."
  }
}

variable "user_hash" {
  description = "Unique user identifier for resource naming"
  type        = string
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9]{3,8}$", var.user_hash))
    error_message = "User hash must be 3-8 characters long and contain only letters and numbers."
  }
}

variable "environment_name" {
  description = "Name of the ADE environment"
  type        = string
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{1,63}$", var.environment_name))
    error_message = "Environment name must be 1-63 characters long and contain only letters, numbers, and hyphens."
  }
}

variable "budget_amount" {
  description = "Budget amount in USD"
  type        = number
  
  validation {
    condition     = var.budget_amount > 0 && var.budget_amount <= 10000
    error_message = "Budget amount must be between 1 and 10,000 USD."
  }
}

variable "budget_start_date" {
  description = "Budget start date (YYYY-MM-DD format)"
  type        = string
  
  validation {
    condition     = can(regex("^\\d{4}-\\d{2}-\\d{2}$", var.budget_start_date))
    error_message = "Budget start date must be in YYYY-MM-DD format."
  }
}

variable "budget_end_date" {
  description = "Budget end date (YYYY-MM-DD format)"
  type        = string
  
  validation {
    condition     = can(regex("^\\d{4}-\\d{2}-\\d{2}$", var.budget_end_date))
    error_message = "Budget end date must be in YYYY-MM-DD format."
  }
}

variable "devops_team_email" {
  description = "DevOps team email for notifications"
  type        = string
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.devops_team_email))
    error_message = "DevOps team email must be a valid email address."
  }
}

variable "finance_team_email" {
  description = "Finance team email for notifications"
  type        = string
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.finance_team_email))
    error_message = "Finance team email must be a valid email address."
  }
}

variable "slack_webhook_url" {
  description = "Slack webhook URL for notifications"
  type        = string
  sensitive   = true
  
  validation {
    condition     = can(regex("^https://hooks.slack.com/services/.*", var.slack_webhook_url))
    error_message = "Slack webhook URL must be a valid Slack webhook URL starting with https://hooks.slack.com/services/."
  }
}

variable "ade_resource_group_name" {
  description = "The resource group containing the ADE Dev Center"
  type        = string
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9-._\\(\\)]{1,90}$", var.ade_resource_group_name))
    error_message = "ADE resource group name must be 1-90 characters and can contain alphanumeric, underscore, parentheses, hyphen, and period characters."
  }
}

variable "ade_dev_center_name" {
  description = "The name of the ADE Dev Center"
  type        = string
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{3,26}$", var.ade_dev_center_name))
    error_message = "ADE Dev Center name must be 3-26 characters long and contain only letters, numbers, and hyphens."
  }
}

variable "expiration_date" {
  description = "Environment expiration date (YYYY-MM-DD format)"
  type        = string
  
  validation {
    condition     = can(regex("^\\d{4}-\\d{2}-\\d{2}$", var.expiration_date))
    error_message = "Expiration date must be in YYYY-MM-DD format."
  }
}

# ==============================================================================
# BUDGET CONFIGURATION
# ==============================================================================

variable "alert_thresholds" {
  description = "Budget alert thresholds configuration"
  type = object({
    high_usage_threshold = number
    critical_threshold   = number
    budget_exceeded     = number
    forecast_threshold  = number
  })
  default = {
    high_usage_threshold = 80
    critical_threshold   = 95
    budget_exceeded     = 100
    forecast_threshold  = 90
  }
  
  validation {
    condition = (
      var.alert_thresholds.high_usage_threshold > 0 && var.alert_thresholds.high_usage_threshold <= 100 &&
      var.alert_thresholds.critical_threshold > 0 && var.alert_thresholds.critical_threshold <= 100 &&
      var.alert_thresholds.budget_exceeded > 0 && var.alert_thresholds.budget_exceeded <= 100 &&
      var.alert_thresholds.forecast_threshold > 0 && var.alert_thresholds.forecast_threshold <= 100
    )
    error_message = "All alert thresholds must be between 1 and 100."
  }
}

# ==============================================================================
# SLACK INTEGRATION CONFIGURATION
# ==============================================================================

variable "slack_integration_name" {
  description = "The name of the Logic App for Slack integration"
  type        = string
  default     = "ade-slack-integration"
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{1,80}$", var.slack_integration_name))
    error_message = "Slack integration name must be 1-80 characters long and contain only letters, numbers, and hyphens."
  }
}

variable "event_grid_topic_name" {
  description = "The Event Grid topic name for ADE events"
  type        = string
  default     = "ade-events"
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{3,50}$", var.event_grid_topic_name))
    error_message = "Event Grid topic name must be 3-50 characters long and contain only letters, numbers, and hyphens."
  }
}

variable "notification_settings" {
  description = "Configuration for Slack notification formatting and timing"
  type = object({
    channel_prefix    = optional(string, "#ade-")
    mention_users     = optional(bool, false)
    include_cost_info = optional(bool, true)
    timezone         = optional(string, "UTC")
    retry_attempts   = optional(number, 3)
  })
  default = {}
}

variable "event_filter_settings" {
  description = "Configuration for filtering ADE events"
  type = object({
    environment_types = optional(list(string), ["production", "staging"])
    cost_threshold   = optional(number, 100)
    critical_events  = optional(list(string), ["EnvironmentExpiring", "BudgetExceeded"])
  })
  default = {}
}

# ==============================================================================
# POLICY GOVERNANCE CONFIGURATION
# ==============================================================================

variable "policy_enforcement_mode" {
  description = "Policy enforcement mode (Default, DoNotEnforce)"
  type        = string
  default     = "Default"
  
  validation {
    condition = contains([
      "Default", "DoNotEnforce"
    ], var.policy_enforcement_mode)
    error_message = "Policy enforcement mode must be either 'Default' or 'DoNotEnforce'."
  }
}

variable "policy_required_tags" {
  description = "List of required tags that must be present on all resources"
  type        = list(string)
  default = [
    "environment-name",
    "user-email", 
    "expiration-date",
    "environment-type",
    "cost-center",
    "business-unit",
    "project-code"
  ]
  
  validation {
    condition     = length(var.policy_required_tags) > 0
    error_message = "At least one required tag must be specified."
  }
}

variable "policy_allowed_locations" {
  description = "List of allowed Azure regions for resource deployment"
  type        = list(string)
  default = [
    "eastus", "eastus2", "westus", "westus2", "centralus",
    "northeurope", "westeurope"
  ]
  
  validation {
    condition     = length(var.policy_allowed_locations) > 0
    error_message = "At least one allowed location must be specified."
  }
}

variable "policy_allowed_resource_types" {
  description = "List of allowed Azure resource types (empty list means all types allowed)"
  type        = list(string)
  default     = []
}

variable "policy_denied_resource_types" {
  description = "List of denied Azure resource types that cannot be deployed"
  type        = list(string)
  default = [
    "Microsoft.Compute/virtualMachines",
    "Microsoft.ClassicCompute/virtualMachines"
  ]
}

# ==============================================================================
# OPTIONAL CONFIGURATION
# ==============================================================================

variable "environment_type" {
  description = "The type of environment (development, testing, staging, production)"
  type        = string
  default     = "development"
  
  validation {
    condition = contains([
      "development", "testing", "staging", "production"
    ], var.environment_type)
    error_message = "Environment type must be one of: development, testing, staging, production."
  }
}

variable "cost_center" {
  description = "Cost center for resource billing and tracking"
  type        = string
  default     = "engineering"
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{1,50}$", var.cost_center))
    error_message = "Cost center must be 1-50 characters long and contain only letters, numbers, and hyphens."
  }
}

variable "business_unit" {
  description = "Business unit responsible for the environment"
  type        = string
  default     = "platform-engineering"
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{1,50}$", var.business_unit))
    error_message = "Business unit must be 1-50 characters long and contain only letters, numbers, and hyphens."
  }
}

variable "project_code" {
  description = "Project code for resource tracking"
  type        = string
  default     = "ADE-2024"
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{1,50}$", var.project_code))
    error_message = "Project code must be 1-50 characters long and contain only letters, numbers, and hyphens."
  }
}

# ==============================================================================
# INFRASTRUCTURE CONFIGURATION
# ==============================================================================

variable "storage_account_tier" {
  description = "The performance tier of the storage account"
  type        = string
  default     = "Standard"
  
  validation {
    condition = contains([
      "Standard", "Premium"
    ], var.storage_account_tier)
    error_message = "Storage account tier must be either 'Standard' or 'Premium'."
  }
}

variable "storage_replication_type" {
  description = "The replication type for the storage account"
  type        = string
  default     = "LRS"
  
  validation {
    condition = contains([
      "LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"
    ], var.storage_replication_type)
    error_message = "Storage replication type must be one of: LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS."
  }
}

variable "storage_access_tier" {
  description = "The access tier for the storage account"
  type        = string
  default     = "Hot"
  
  validation {
    condition = contains([
      "Hot", "Cool"
    ], var.storage_access_tier)
    error_message = "Storage access tier must be either 'Hot' or 'Cool'."
  }
}

variable "log_analytics_sku" {
  description = "The SKU of the Log Analytics workspace"
  type        = string
  default     = "PerGB2018"
  
  validation {
    condition = contains([
      "Free", "PerNode", "Premium", "Standard", "Standalone", "Unlimited", "CapacityReservation", "PerGB2018"
    ], var.log_analytics_sku)
    error_message = "Log Analytics SKU must be a valid pricing tier."
  }
}

variable "log_retention_days" {
  description = "The number of days to retain logs in Log Analytics"
  type        = number
  default     = 30
  
  validation {
    condition     = var.log_retention_days >= 30 && var.log_retention_days <= 730
    error_message = "Log retention days must be between 30 and 730."
  }
}

variable "key_vault_sku" {
  description = "The SKU of the Key Vault"
  type        = string
  default     = "standard"
  
  validation {
    condition = contains([
      "standard", "premium"
    ], var.key_vault_sku)
    error_message = "Key Vault SKU must be either 'standard' or 'premium'."
  }
}

variable "soft_delete_retention_days" {
  description = "The number of days to retain deleted secrets in Key Vault"
  type        = number
  default     = 30
  
  validation {
    condition     = var.soft_delete_retention_days >= 7 && var.soft_delete_retention_days <= 90
    error_message = "Soft delete retention days must be between 7 and 90."
  }
}

# ==============================================================================
# SECURITY AND COMPLIANCE
# ==============================================================================

variable "enable_deletion_protection" {
  description = "Enable deletion protection for critical resources"
  type        = bool
  default     = true
}

variable "enable_purge_protection" {
  description = "Enable purge protection for Key Vault (recommended for production)"
  type        = bool
  default     = true
}

variable "enable_rbac_authorization" {
  description = "Enable RBAC authorization for Key Vault access"
  type        = bool
  default     = true
}

variable "allow_public_access" {
  description = "Allow public network access to storage accounts"
  type        = bool
  default     = false
}

variable "enable_budget_policies" {
  description = "Enable budget-related policy assignments"
  type        = bool
  default     = true
}

variable "max_cost_threshold" {
  description = "Maximum cost threshold for budget policies (USD)"
  type        = number
  default     = 500
  
  validation {
    condition     = var.max_cost_threshold > 0 && var.max_cost_threshold <= 10000
    error_message = "Maximum cost threshold must be between 1 and 10000 USD."
  }
}

variable "enable_security_policies" {
  description = "Enable security-related policy assignments"
  type        = bool
  default     = true
}

variable "require_https_only" {
  description = "Require HTTPS-only traffic for applicable resources"
  type        = bool
  default     = true
}

variable "require_encryption_at_rest" {
  description = "Require encryption at rest for storage resources"
  type        = bool
  default     = true
}

variable "enable_monitoring_policies" {
  description = "Enable monitoring and diagnostics policy assignments"
  type        = bool
  default     = true
}

variable "enable_activity_log_alerts" {
  description = "Enable activity log alert policies"
  type        = bool
  default     = true
}

# ==============================================================================
# ADDITIONAL TAGS
# ==============================================================================

variable "additional_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
  
  validation {
    condition     = alltrue([for v in values(var.additional_tags) : can(regex("^.{1,256}$", v))])
    error_message = "Tag values must be 1-256 characters long."
  }
}