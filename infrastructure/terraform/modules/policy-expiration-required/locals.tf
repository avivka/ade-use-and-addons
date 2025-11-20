# ==============================================================================
# LOCALS
# Policy Governance Module
# ==============================================================================

locals {
  # ==============================================================================
  # SCOPE DETERMINATION
  # ==============================================================================
  
  # Determine the scope for policy assignments
  assignment_scope = var.resource_group_name != null ? data.azurerm_resource_group.target[0].id : "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
  scope_type       = var.resource_group_name != null ? "resource-group" : "subscription"
  
  # ==============================================================================
  # RESOURCE NAMING
  # ==============================================================================
  
  # Resource naming conventions following Azure best practices
  random_suffix = random_string.suffix.result
  
  # Policy assignment names
  assignment_name_prefix = "ade-governance"
  
  # ==============================================================================
  # TAGGING STRATEGY
  # ==============================================================================
  
  # Common tags applied to all policy assignments
  common_tags = merge({
    # Core identification tags
    "purpose"          = "ade-governance"
    "environment"      = var.environment_type
    "environment-name" = var.environment_name
    "user-email"       = var.user_email
    "expiration-date"  = var.expiration_date
    "cost-center"      = var.cost_center
    "business-unit"    = var.business_unit
    "project-code"     = var.project_code
    
    # Operational tags
    "managed-by"       = "terraform"
    "created-date"     = formatdate("YYYY-MM-DD", timestamp())
    "deployment-id"    = random_uuid.deployment_id.result
    
    # Policy-specific tags
    "policy-category"  = "governance"
    "enforcement-mode" = var.enforcement_mode
    "scope-type"       = local.scope_type
    
    # Compliance tags
    "data-classification" = "internal"
    "compliance-required" = "true"
    "audit-required"      = "true"
  }, var.additional_tags)
  
  # ==============================================================================
  # REQUIRED TAG POLICIES
  # ==============================================================================
  
  # Tag values for policy enforcement
  tag_values = {
    "environment-name" = var.environment_name
    "user-email"       = var.user_email
    "expiration-date"  = var.expiration_date
    "environment-type" = var.environment_type
    "cost-center"      = var.cost_center
    "business-unit"    = var.business_unit
    "project-code"     = var.project_code
  }
  
  # Create policy assignments for each required tag
  required_tag_assignments = {
    for tag in var.required_tags : tag => {
      name         = "${local.assignment_name_prefix}-require-${tag}-${local.random_suffix}"
      display_name = "ADE: Require ${tag} tag"
      description  = "Enforces ${tag} tag on all resources in ADE environment ${var.environment_name}"
      tag_name     = tag
      tag_value    = lookup(local.tag_values, tag, "required")
    }
  }
  
  # ==============================================================================
  # LOCATION POLICY CONFIGURATION
  # ==============================================================================
  
  location_policy = {
    name         = "${local.assignment_name_prefix}-allowed-locations-${local.random_suffix}"
    display_name = "ADE: Allowed locations"
    description  = "Restricts resource deployment to approved Azure regions for environment ${var.environment_name}"
    allowed_locations = var.allowed_locations
  }
  
  # ==============================================================================
  # RESOURCE TYPE POLICIES
  # ==============================================================================
  
  # Allowed resource types policy (if specified)
  allowed_resource_types_policy = length(var.allowed_resource_types) > 0 ? {
    name         = "${local.assignment_name_prefix}-allowed-types-${local.random_suffix}"
    display_name = "ADE: Allowed resource types"
    description  = "Restricts deployment to approved resource types for environment ${var.environment_name}"
    resource_types = var.allowed_resource_types
  } : null
  
  # Denied resource types policy
  denied_resource_types_policy = length(var.denied_resource_types) > 0 ? {
    name         = "${local.assignment_name_prefix}-denied-types-${local.random_suffix}"
    display_name = "ADE: Not allowed resource types"
    description  = "Prevents deployment of restricted resource types for environment ${var.environment_name}"
    resource_types = var.denied_resource_types
  } : null
  
  # ==============================================================================
  # SECURITY POLICIES
  # ==============================================================================
  
  # HTTPS-only storage policy
  https_storage_policy = var.require_https_only ? {
    name         = "${local.assignment_name_prefix}-https-storage-${local.random_suffix}"
    display_name = "ADE: Require HTTPS for storage accounts"
    description  = "Ensures all storage accounts use HTTPS-only traffic for environment ${var.environment_name}"
  } : null
  
  # Encryption at rest policy
  encryption_storage_policy = var.require_encryption_at_rest ? {
    name         = "${local.assignment_name_prefix}-encrypt-storage-${local.random_suffix}"
    display_name = "ADE: Require storage encryption"
    description  = "Ensures all storage accounts use encryption at rest for environment ${var.environment_name}"
  } : null
  
  # ==============================================================================
  # MONITORING POLICIES
  # ==============================================================================
  
  # Activity log alert policy
  activity_log_policy = var.enable_activity_log_alerts ? {
    name         = "${local.assignment_name_prefix}-activity-logs-${local.random_suffix}"
    display_name = "ADE: Activity log monitoring"
    description  = "Enables activity log monitoring for environment ${var.environment_name}"
  } : null
  
  # ==============================================================================
  # BUDGET POLICIES
  # ==============================================================================
  
  # Budget threshold policy
  budget_policy = var.enable_budget_policies ? {
    name         = "${local.assignment_name_prefix}-budget-control-${local.random_suffix}"
    display_name = "ADE: Budget threshold control"
    description  = "Enforces budget thresholds for environment ${var.environment_name}"
    max_threshold = var.max_cost_threshold
  } : null
  
  # ==============================================================================
  # COMPUTED VALUES
  # ==============================================================================
  
  # Current timestamp for tracking
  timestamp = timestamp()
  
  # Policy assignment parameters for different policies
  common_assignment_parameters = {
    enforcement_mode = var.enforcement_mode
    location        = var.location
    scope           = local.assignment_scope
    tags            = local.common_tags
  }
}