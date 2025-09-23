# ==============================================================================
# VARIABLES
# Azure Deployment Environments - Budget Governance Variables
# ==============================================================================

# ==============================================================================
# REQUIRED VARIABLES
# ==============================================================================

variable "user_email" {
  description = "User email address for budget allocation and notifications"
  type        = string
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.user_email))
    error_message = "The user_email must be a valid email address."
  }
}

variable "user_hash" {
  description = "User hash for budget name uniqueness (8 characters)"
  type        = string
  
  validation {
    condition     = length(var.user_hash) == 8 && can(regex("^[a-f0-9]+$", var.user_hash))
    error_message = "The user_hash must be exactly 8 hexadecimal characters."
  }
}

variable "environment_name" {
  description = "Environment name for tracking and tagging"
  type        = string
  
  validation {
    condition     = length(var.environment_name) >= 3 && length(var.environment_name) <= 24
    error_message = "The environment_name must be between 3 and 24 characters."
  }
}

variable "resource_group_name" {
  description = "Name of the resource group where resources will be deployed"
  type        = string
  
  validation {
    condition     = length(var.resource_group_name) >= 1 && length(var.resource_group_name) <= 90
    error_message = "The resource_group_name must be between 1 and 90 characters."
  }
}

# ==============================================================================
# OPTIONAL VARIABLES WITH DEFAULTS
# ==============================================================================

variable "budget_amount" {
  description = "Budget amount in USD per user"
  type        = number
  default     = 200
  
  validation {
    condition     = var.budget_amount > 0 && var.budget_amount <= 10000
    error_message = "The budget_amount must be between 1 and 10000 USD."
  }
}

variable "budget_start_date" {
  description = "Budget start date in YYYY-MM-DD format"
  type        = string
  default     = "2024-01-01"
  
  validation {
    condition     = can(regex("^\\d{4}-\\d{2}-\\d{2}$", var.budget_start_date))
    error_message = "The budget_start_date must be in YYYY-MM-DD format."
  }
}

variable "budget_end_date" {
  description = "Budget end date in YYYY-MM-DD format"
  type        = string
  default     = "2024-12-31"
  
  validation {
    condition     = can(regex("^\\d{4}-\\d{2}-\\d{2}$", var.budget_end_date))
    error_message = "The budget_end_date must be in YYYY-MM-DD format."
  }
}

variable "expiration_date" {
  description = "Environment expiration date for compliance tracking"
  type        = string
  
  validation {
    condition     = can(regex("^\\d{4}-\\d{2}-\\d{2}$", var.expiration_date))
    error_message = "The expiration_date must be in YYYY-MM-DD format."
  }
}

variable "location" {
  description = "Azure region for resource deployment"
  type        = string
  default     = "East US 2"
  
  validation {
    condition = contains([
      "East US", "East US 2", "West US", "West US 2", "West US 3",
      "Central US", "South Central US", "North Central US", "West Central US",
      "Canada Central", "Canada East",
      "North Europe", "West Europe", "UK South", "UK West",
      "France Central", "Germany West Central", "Switzerland North",
      "Norway East", "Sweden Central",
      "Southeast Asia", "East Asia", "Australia East", "Australia Southeast",
      "Japan East", "Japan West", "Korea Central", "India Central",
      "Brazil South", "South Africa North"
    ], var.location)
    error_message = "The location must be a valid Azure region."
  }
}

variable "environment_type" {
  description = "Type of environment (development, testing, staging, production)"
  type        = string
  default     = "development"
  
  validation {
    condition     = contains(["development", "testing", "staging", "production"], var.environment_type)
    error_message = "The environment_type must be one of: development, testing, staging, production."
  }
}

# ==============================================================================
# NOTIFICATION CONFIGURATION
# ==============================================================================

variable "devops_team_email" {
  description = "DevOps team email address for budget notifications"
  type        = string
  default     = "devops-team@company.com"
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.devops_team_email))
    error_message = "The devops_team_email must be a valid email address."
  }
}

variable "finance_team_email" {
  description = "Finance team email address for budget exceeded notifications"
  type        = string
  default     = "finance-team@company.com"
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.finance_team_email))
    error_message = "The finance_team_email must be a valid email address."
  }
}

# ==============================================================================
# ALERT THRESHOLD CONFIGURATION
# ==============================================================================

variable "alert_thresholds" {
  description = "Budget alert thresholds configuration"
  type = object({
    high_usage_threshold    = number
    critical_threshold     = number
    budget_exceeded        = number
    forecast_threshold     = number
  })
  
  default = {
    high_usage_threshold = 80
    critical_threshold   = 95
    budget_exceeded      = 100
    forecast_threshold   = 90
  }
  
  validation {
    condition = (
      var.alert_thresholds.high_usage_threshold > 0 &&
      var.alert_thresholds.critical_threshold > var.alert_thresholds.high_usage_threshold &&
      var.alert_thresholds.budget_exceeded >= var.alert_thresholds.critical_threshold &&
      var.alert_thresholds.forecast_threshold > 0 &&
      var.alert_thresholds.forecast_threshold <= 100
    )
    error_message = "Alert thresholds must be positive numbers with logical progression."
  }
}

# ==============================================================================
# STORAGE CONFIGURATION
# ==============================================================================

variable "storage_account_tier" {
  description = "Storage account performance tier"
  type        = string
  default     = "Standard"
  
  validation {
    condition     = contains(["Standard", "Premium"], var.storage_account_tier)
    error_message = "The storage_account_tier must be either Standard or Premium."
  }
}

variable "storage_replication_type" {
  description = "Storage account replication type"
  type        = string
  default     = "LRS"
  
  validation {
    condition     = contains(["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"], var.storage_replication_type)
    error_message = "The storage_replication_type must be a valid Azure storage replication type."
  }
}

variable "storage_access_tier" {
  description = "Storage account access tier for cost optimization"
  type        = string
  default     = "Cool"
  
  validation {
    condition     = contains(["Hot", "Cool"], var.storage_access_tier)
    error_message = "The storage_access_tier must be either Hot or Cool."
  }
}

# ==============================================================================
# LOG ANALYTICS CONFIGURATION
# ==============================================================================

variable "log_retention_days" {
  description = "Log Analytics workspace retention period in days"
  type        = number
  default     = 90
  
  validation {
    condition     = var.log_retention_days >= 30 && var.log_retention_days <= 730
    error_message = "The log_retention_days must be between 30 and 730 days."
  }
}

variable "log_analytics_sku" {
  description = "Log Analytics workspace pricing tier"
  type        = string
  default     = "PerGB2018"
  
  validation {
    condition     = contains(["Free", "PerNode", "PerGB2018", "Standalone", "Standard", "Premium"], var.log_analytics_sku)
    error_message = "The log_analytics_sku must be a valid Log Analytics SKU."
  }
}

# ==============================================================================
# TAGGING CONFIGURATION
# ==============================================================================

variable "additional_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection for critical resources"
  type        = bool
  default     = true
}