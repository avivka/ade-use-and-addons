# ==============================================================================
# MAIN CONFIGURATION
# Policy Governance Module
# ==============================================================================

# ==============================================================================
# REQUIRED TAG POLICY ASSIGNMENTS
# ==============================================================================

# Create policy assignments for each required tag
resource "azurerm_resource_policy_assignment" "require_tags" {
  for_each = local.required_tag_assignments

  name                 = each.value.name
  policy_definition_id = data.azurerm_policy_definition.require_tag_and_value.id
  resource_id          = local.assignment_scope
  display_name         = each.value.display_name
  description          = each.value.description
  location             = var.location

  # Policy parameters
  parameters = jsonencode({
    tagName = {
      value = each.value.tag_name
    }
    tagValue = {
      value = each.value.tag_value
    }
  })

  # Managed identity for policy remediation
  identity {
    type = "SystemAssigned"
  }

  # Metadata
  metadata = jsonencode({
    category    = "Tags"
    environment = var.environment_name
    createdBy   = "terraform-ade-governance"
    version     = "1.0"
  })

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      metadata
    ]
  }
}

# ==============================================================================
# LOCATION RESTRICTION POLICY
# ==============================================================================

resource "azurerm_resource_policy_assignment" "allowed_locations" {
  name                 = local.location_policy.name
  policy_definition_id = data.azurerm_policy_definition.allowed_locations.id
  resource_id          = local.assignment_scope
  display_name         = local.location_policy.display_name
  description          = local.location_policy.description
  location             = var.location

  # Policy parameters
  parameters = jsonencode({
    listOfAllowedLocations = {
      value = local.location_policy.allowed_locations
    }
  })

  # Managed identity for policy remediation
  identity {
    type = "SystemAssigned"
  }

  # Metadata
  metadata = jsonencode({
    category    = "General"
    environment = var.environment_name
    createdBy   = "terraform-ade-governance"
    version     = "1.0"
  })

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      metadata
    ]
  }
}

# ==============================================================================
# ALLOWED RESOURCE TYPES POLICY (CONDITIONAL)
# ==============================================================================

resource "azurerm_resource_policy_assignment" "allowed_resource_types" {
  count = local.allowed_resource_types_policy != null ? 1 : 0

  name                 = local.allowed_resource_types_policy.name
  policy_definition_id = data.azurerm_policy_definition.allowed_resource_types[0].id
  resource_id          = local.assignment_scope
  display_name         = local.allowed_resource_types_policy.display_name
  description          = local.allowed_resource_types_policy.description
  location             = var.location

  # Policy parameters
  parameters = jsonencode({
    listOfResourceTypesAllowed = {
      value = local.allowed_resource_types_policy.resource_types
    }
  })

  # Managed identity for policy remediation
  identity {
    type = "SystemAssigned"
  }

  # Metadata
  metadata = jsonencode({
    category    = "General"
    environment = var.environment_name
    createdBy   = "terraform-ade-governance"
    version     = "1.0"
  })

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      metadata
    ]
  }
}

# ==============================================================================
# DENIED RESOURCE TYPES POLICY (CONDITIONAL)
# ==============================================================================

resource "azurerm_resource_policy_assignment" "denied_resource_types" {
  count = local.denied_resource_types_policy != null ? 1 : 0

  name                 = local.denied_resource_types_policy.name
  policy_definition_id = data.azurerm_policy_definition.not_allowed_resource_types[0].id
  resource_id          = local.assignment_scope
  display_name         = local.denied_resource_types_policy.display_name
  description          = local.denied_resource_types_policy.description
  location             = var.location

  # Policy parameters
  parameters = jsonencode({
    listOfResourceTypesNotAllowed = {
      value = local.denied_resource_types_policy.resource_types
    }
  })

  # Managed identity for policy remediation
  identity {
    type = "SystemAssigned"
  }

  # Metadata
  metadata = jsonencode({
    category    = "General"
    environment = var.environment_name
    createdBy   = "terraform-ade-governance"
    version     = "1.0"
  })

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      metadata
    ]
  }
}

# ==============================================================================
# HTTPS STORAGE POLICY (CONDITIONAL)
# ==============================================================================

resource "azurerm_resource_policy_assignment" "https_storage" {
  count = local.https_storage_policy != null ? 1 : 0

  name                 = local.https_storage_policy.name
  policy_definition_id = data.azurerm_policy_definition.require_https_storage[0].id
  resource_id          = local.assignment_scope
  display_name         = local.https_storage_policy.display_name
  description          = local.https_storage_policy.description
  location             = var.location

  # Managed identity for policy remediation
  identity {
    type = "SystemAssigned"
  }

  # Metadata
  metadata = jsonencode({
    category    = "Security"
    environment = var.environment_name
    createdBy   = "terraform-ade-governance"
    version     = "1.0"
  })

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      metadata
    ]
  }
}

# ==============================================================================
# STORAGE ENCRYPTION POLICY (CONDITIONAL)
# ==============================================================================

resource "azurerm_resource_policy_assignment" "storage_encryption" {
  count = local.encryption_storage_policy != null ? 1 : 0

  name                 = local.encryption_storage_policy.name
  policy_definition_id = data.azurerm_policy_definition.require_encryption_storage[0].id
  resource_id          = local.assignment_scope
  display_name         = local.encryption_storage_policy.display_name
  description          = local.encryption_storage_policy.description
  location             = var.location

  # Managed identity for policy remediation
  identity {
    type = "SystemAssigned"
  }

  # Metadata
  metadata = jsonencode({
    category    = "Security"
    environment = var.environment_name
    createdBy   = "terraform-ade-governance"
    version     = "1.0"
  })

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      metadata
    ]
  }
}