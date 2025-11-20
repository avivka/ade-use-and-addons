# ==============================================================================
# VARIABLES
# Policy Governance Module
# ==============================================================================

# ==============================================================================
# REQUIRED VARIABLES
# ==============================================================================

variable "environment_name" {
  description = "Environment name for tagging and policy enforcement"
  type        = string
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{1,63}$", var.environment_name))
    error_message = "Environment name must be 1-63 characters long and contain only letters, numbers, and hyphens."
  }
}

variable "user_email" {
  description = "User email for tagging and policy enforcement"
  type        = string
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.user_email))
    error_message = "User email must be a valid email address."
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

variable "environment_type" {
  description = "The type of environment (development, testing, staging, production)"
  type        = string
  
  validation {
    condition = contains([
      "development", "testing", "staging", "production"
    ], var.environment_type)
    error_message = "Environment type must be one of: development, testing, staging, production."
  }
}

variable "location" {
  description = "The Azure region for policy assignments"
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

# ==============================================================================
# OPTIONAL VARIABLES
# ==============================================================================

variable "resource_group_name" {
  description = "The name of the resource group where policies will be assigned (if not provided, assigns to subscription)"
  type        = string
  default     = null
  
  validation {
    condition     = var.resource_group_name == null || can(regex("^[a-zA-Z0-9-._\\(\\)]{1,90}$", var.resource_group_name))
    error_message = "Resource group name must be 1-90 characters and can contain alphanumeric, underscore, parentheses, hyphen, and period characters."
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
# POLICY CONFIGURATION
# ==============================================================================

variable "enforcement_mode" {
  description = "Policy enforcement mode (Default, DoNotEnforce)"
  type        = string
  default     = "Default"
  
  validation {
    condition = contains([
      "Default", "DoNotEnforce"
    ], var.enforcement_mode)
    error_message = "Enforcement mode must be either 'Default' or 'DoNotEnforce'."
  }
}

variable "required_tags" {
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
    condition     = length(var.required_tags) > 0
    error_message = "At least one required tag must be specified."
  }
}

variable "allowed_locations" {
  description = "List of allowed Azure regions for resource deployment"
  type        = list(string)
  default = [
    "eastus", "eastus2", "westus", "westus2", "centralus",
    "northeurope", "westeurope"
  ]
  
  validation {
    condition     = length(var.allowed_locations) > 0
    error_message = "At least one allowed location must be specified."
  }
}

variable "allowed_resource_types" {
  description = "List of allowed Azure resource types (empty list means all types allowed)"
  type        = list(string)
  default     = []
}

variable "denied_resource_types" {
  description = "List of denied Azure resource types that cannot be deployed"
  type        = list(string)
  default = [
    "Microsoft.Compute/virtualMachines",
    "Microsoft.ClassicCompute/virtualMachines"
  ]
}

# ==============================================================================
# BUDGET AND COST MANAGEMENT
# ==============================================================================

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

# ==============================================================================
# SECURITY POLICIES
# ==============================================================================

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

# ==============================================================================
# MONITORING AND COMPLIANCE
# ==============================================================================

variable "enable_monitoring_policies" {
  description = "Enable monitoring and diagnostics policy assignments"
  type        = bool
  default     = true
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for diagnostic settings (optional)"
  type        = string
  default     = null
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
  description = "Additional tags to apply to policy assignments"
  type        = map(string)
  default     = {}
  
  validation {
    condition     = alltrue([for v in values(var.additional_tags) : can(regex("^.{1,256}$", v))])
    error_message = "Tag values must be 1-256 characters long."
  }
}