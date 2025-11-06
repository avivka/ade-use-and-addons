variable "name_prefix" {}
variable "location" {}
variable "resource_group_name" {}

resource "azurerm_key_vault" "kv" {
  name                        = "${var.name_prefix}kv${random_string.suffix.result}"
  location                    = var.location
  resource_group_name         = var.resource_group_name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  purge_protection_enabled    = true
  soft_delete_retention_days  = 7
}

data "azurerm_client_config" "current" {}

resource "random_string" "suffix" {
  length  = 4
  upper   = false
  special = false
}

output "id"   { value = azurerm_key_vault.kv.id }
output "name" { value = azurerm_key_vault.kv.name }
