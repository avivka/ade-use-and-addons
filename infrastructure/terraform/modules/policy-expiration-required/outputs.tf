# ==============================================================================
# OUTPUTS
# Policy Governance Module
# ==============================================================================

# ==============================================================================
# POLICY ASSIGNMENT INFORMATION
# ==============================================================================

output "required_tag_assignments" {
  description = "Information about required tag policy assignments"
  value = {
    for k, v in azurerm_resource_policy_assignment.require_tags : k => {
      name         = v.name
      id           = v.id
      display_name = v.display_name
      scope        = v.resource_id
    }
  }
  sensitive = false
}

output "location_policy_assignment" {
  description = "Information about the location restriction policy assignment"
  value = {
    name         = azurerm_resource_policy_assignment.allowed_locations.name
    id           = azurerm_resource_policy_assignment.allowed_locations.id
    display_name = azurerm_resource_policy_assignment.allowed_locations.display_name
    scope        = azurerm_resource_policy_assignment.allowed_locations.resource_id
  }
  sensitive = false
}

output "allowed_resource_types_assignment" {
  description = "Information about the allowed resource types policy assignment"
  value = length(azurerm_resource_policy_assignment.allowed_resource_types) > 0 ? {
    name         = azurerm_resource_policy_assignment.allowed_resource_types[0].name
    id           = azurerm_resource_policy_assignment.allowed_resource_types[0].id
    display_name = azurerm_resource_policy_assignment.allowed_resource_types[0].display_name
    scope        = azurerm_resource_policy_assignment.allowed_resource_types[0].resource_id
  } : null
  sensitive = false
}

output "denied_resource_types_assignment" {
  description = "Information about the denied resource types policy assignment"
  value = length(azurerm_resource_policy_assignment.denied_resource_types) > 0 ? {
    name         = azurerm_resource_policy_assignment.denied_resource_types[0].name
    id           = azurerm_resource_policy_assignment.denied_resource_types[0].id
    display_name = azurerm_resource_policy_assignment.denied_resource_types[0].display_name
    scope        = azurerm_resource_policy_assignment.denied_resource_types[0].resource_id
  } : null
  sensitive = false
}

output "https_storage_assignment" {
  description = "Information about the HTTPS storage policy assignment"
  value = length(azurerm_resource_policy_assignment.https_storage) > 0 ? {
    name         = azurerm_resource_policy_assignment.https_storage[0].name
    id           = azurerm_resource_policy_assignment.https_storage[0].id
    display_name = azurerm_resource_policy_assignment.https_storage[0].display_name
    scope        = azurerm_resource_policy_assignment.https_storage[0].resource_id
  } : null
  sensitive = false
}

output "storage_encryption_assignment" {
  description = "Information about the storage encryption policy assignment"
  value = length(azurerm_resource_policy_assignment.storage_encryption) > 0 ? {
    name         = azurerm_resource_policy_assignment.storage_encryption[0].name
    id           = azurerm_resource_policy_assignment.storage_encryption[0].id
    display_name = azurerm_resource_policy_assignment.storage_encryption[0].display_name
    scope        = azurerm_resource_policy_assignment.storage_encryption[0].resource_id
  } : null
  sensitive = false
}

# ==============================================================================
# SCOPE AND CONFIGURATION
# ==============================================================================

output "assignment_scope" {
  description = "The scope where policies are assigned"
  value       = local.assignment_scope
  sensitive   = false
}

output "scope_type" {
  description = "The type of scope (resource-group or subscription)"
  value       = local.scope_type
  sensitive   = false
}

output "environment_configuration" {
  description = "Summary of environment configuration"
  value = {
    environment_name = var.environment_name
    environment_type = var.environment_type
    user_email      = var.user_email
    expiration_date = var.expiration_date
    cost_center     = var.cost_center
    business_unit   = var.business_unit
    project_code    = var.project_code
  }
  sensitive = false
}

# ==============================================================================
# POLICY CONFIGURATION SUMMARY
# ==============================================================================

output "policy_configuration" {
  description = "Summary of policy configuration settings"
  value = {
    required_tags              = var.required_tags
    allowed_locations          = var.allowed_locations
    allowed_resource_types     = var.allowed_resource_types
    denied_resource_types      = var.denied_resource_types
    enable_security_policies   = var.enable_security_policies
    enable_monitoring_policies = var.enable_monitoring_policies
    enable_budget_policies     = var.enable_budget_policies
    require_https_only         = var.require_https_only
    require_encryption_at_rest = var.require_encryption_at_rest
    max_cost_threshold         = var.max_cost_threshold
  }
  sensitive = false
}

# ==============================================================================
# RESOURCE IDENTIFIERS
# ==============================================================================

output "resource_group_name" {
  description = "The name of the target resource group (if applicable)"
  value       = var.resource_group_name
  sensitive   = false
}

output "subscription_id" {
  description = "The subscription ID where policies are assigned"
  value       = data.azurerm_client_config.current.subscription_id
  sensitive   = false
}

output "tenant_id" {
  description = "The tenant ID where policies are assigned"
  value       = data.azurerm_client_config.current.tenant_id
  sensitive   = false
}

output "deployment_timestamp" {
  description = "The timestamp when this module was deployed"
  value       = local.timestamp
  sensitive   = false
}

output "random_suffix" {
  description = "The random suffix used for policy assignment naming"
  value       = local.random_suffix
  sensitive   = false
}

# ==============================================================================
# MANAGED IDENTITIES
# ==============================================================================

output "managed_identities" {
  description = "Principal IDs of managed identities created for policy assignments"
  value = merge(
    {
      for k, v in azurerm_resource_policy_assignment.require_tags : 
      "tag_policy_${k}" => v.identity[0].principal_id
    },
    {
      location_policy = azurerm_resource_policy_assignment.allowed_locations.identity[0].principal_id
    },
    length(azurerm_resource_policy_assignment.allowed_resource_types) > 0 ? {
      allowed_types_policy = azurerm_resource_policy_assignment.allowed_resource_types[0].identity[0].principal_id
    } : {},
    length(azurerm_resource_policy_assignment.denied_resource_types) > 0 ? {
      denied_types_policy = azurerm_resource_policy_assignment.denied_resource_types[0].identity[0].principal_id
    } : {},
    length(azurerm_resource_policy_assignment.https_storage) > 0 ? {
      https_storage_policy = azurerm_resource_policy_assignment.https_storage[0].identity[0].principal_id
    } : {},
    length(azurerm_resource_policy_assignment.storage_encryption) > 0 ? {
      storage_encryption_policy = azurerm_resource_policy_assignment.storage_encryption[0].identity[0].principal_id
    } : {}
  )
  sensitive = false
}

# ==============================================================================
# COMPLIANCE STATUS
# ==============================================================================

output "compliance_status" {
  description = "Policy compliance and governance status"
  value = {
    policies_assigned        = true
    tagging_enforced        = length(var.required_tags) > 0
    location_restricted     = true
    resource_types_controlled = length(var.allowed_resource_types) > 0 || length(var.denied_resource_types) > 0
    security_policies_active = var.enable_security_policies
    monitoring_enabled      = var.enable_monitoring_policies
    budget_governance_active = var.enable_budget_policies
    total_tag_policies      = length(var.required_tags)
    total_policies_assigned = (
      length(var.required_tags) + 1 + # tag policies + location policy
      (length(var.allowed_resource_types) > 0 ? 1 : 0) +
      (length(var.denied_resource_types) > 0 ? 1 : 0) +
      (var.require_https_only ? 1 : 0) +
      (var.require_encryption_at_rest ? 1 : 0)
    )
  }
  sensitive = false
}

# ==============================================================================
# TAGS APPLIED
# ==============================================================================

output "applied_tags" {
  description = "The tags that would be applied to all resources in scope"
  value       = local.common_tags
  sensitive   = false
}