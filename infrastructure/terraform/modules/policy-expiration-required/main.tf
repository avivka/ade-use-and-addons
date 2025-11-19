variable "assignment_scope" {}

resource "azurerm_policy_definition" "require_exp" {
  name         = "require-ade-expiresOn"
  display_name = "Require ade:expiresOn tag on resource groups"
  mode         = "All"
  policy_type  = "Custom"
  policy_rule  = jsonencode({
    if = {
      allOf = [
        { field = "type", equals = "Microsoft.Resources/resourceGroups" },
        { not = { field = "tags['ade:expiresOn']", exists = true } }
      ]
    }
    then = { effect = "deny" }
  })
}

resource "azurerm_policy_assignment" "assign_exp" {
  name                 = "require-ade-expiresOn"
  scope                = var.assignment_scope
  policy_definition_id = azurerm_policy_definition.require_exp.id
}
