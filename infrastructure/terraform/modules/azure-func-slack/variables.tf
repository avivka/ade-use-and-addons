# ==============================================================================
# VARIABLES
# Logic App Slack Integration Module
# ==============================================================================

# ==============================================================================
# REQUIRED VARIABLES
# ==============================================================================

variable "logic_app_name" {
  description = "The name of the Logic App workflow"
  type        = string
  default     = "ade-slack-integration"
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{1,80}$", var.logic_app_name))
    error_message = "Logic app name must be 1-80 characters long and contain only letters, numbers, and hyphens."
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

variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9-._\\(\\)]{1,90}$", var.resource_group_name))
    error_message = "Resource group name must be 1-90 characters and can contain alphanumeric, underscore, parentheses, hyphen, and period characters."
  }
}

variable "slack_webhook_url" {
  description = "The Slack webhook URL for notifications (stored securely in Key Vault)"
  type        = string
  sensitive   = true
  
  validation {
    condition     = can(regex("^https://hooks.slack.com/services/.*", var.slack_webhook_url))
    error_message = "Slack webhook URL must be a valid Slack webhook URL starting with https://hooks.slack.com/services/."
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

# ==============================================================================
# OPTIONAL VARIABLES
# ==============================================================================

variable "environment_type" {
  description = "The type of environment (development, testing, staging, production)"
  type        = string
  default     = "production"
  
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
  default     = "devops"
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{1,50}$", var.cost_center))
    error_message = "Cost center must be 1-50 characters long and contain only letters, numbers, and hyphens."
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
  description = "Allow public network access to storage account"
  type        = bool
  default     = false
}

variable "additional_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
  
  validation {
    condition     = alltrue([for v in values(var.additional_tags) : can(regex("^.{1,256}$", v))])
    error_message = "Tag values must be 1-256 characters long."
  }
}

# ==============================================================================
# NOTIFICATION SETTINGS
# ==============================================================================

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

# ==============================================================================
# EVENT FILTERING
# ==============================================================================

variable "event_filter_settings" {
  description = "Configuration for filtering ADE events"
  type = object({
    environment_types = optional(list(string), ["production", "staging"])
    cost_threshold   = optional(number, 100)
    critical_events  = optional(list(string), ["EnvironmentExpiring", "BudgetExceeded"])
  })
  default = {}
}