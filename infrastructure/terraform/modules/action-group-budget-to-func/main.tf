variable "name_prefix" {}
variable "resource_group_name" {}
variable "function_app_id" {}
variable "function_name" {}

resource "azurerm_monitor_action_group" "ag" {
  name                = "${var.name_prefix}-budget-ag"
  resource_group_name = var.resource_group_name
  short_name          = "budgFn"

  azure_function_receiver {
    name                     = "budgetAlert"
    function_app_resource_id = var.function_app_id
    function_name            = var.function_name
    use_common_alert_schema  = true
  }
}

output "id" { value = azurerm_monitor_action_group.ag.id }
