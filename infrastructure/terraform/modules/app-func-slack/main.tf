variable "name_prefix" {}
variable "location" {}
variable "resource_group_name" {}
variable "kv_id" {}
variable "kv_secret_id_slack" {}
variable "subscription_id" {}
variable "app_settings_extra" { type = map(string) default = {} }

resource "azurerm_storage_account" "sa" {
  name                     = "${var.name_prefix}sa${random_string.suffix.result}"
  location                 = var.location
  resource_group_name      = var.resource_group_name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_service_plan" "asp" {
  name                = "${var.name_prefix}-plan"
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"
  sku_name            = "Y1" # consumption
}

resource "azurerm_application_insights" "ai" {
  name                = "${var.name_prefix}-ai"
  location            = var.location
  resource_group_name = var.resource_group_name
  application_type    = "web"
}

resource "azurerm_linux_function_app" "fn" {
  name                       = "${var.name_prefix}-fn"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  storage_account_name       = azurerm_storage_account.sa.name
  storage_account_access_key = azurerm_storage_account.sa.primary_access_key
  service_plan_id            = azurerm_service_plan.asp.id
  https_only                 = true
  functions_extension_version = "~4"

  identity { type = "SystemAssigned" }

  site_config {
    application_insights_key = azurerm_application_insights.ai.instrumentation_key
    linux_fx_version         = "Python|3.11"
    ftps_state               = "Disabled"
  }

  app_settings = merge({
    "WEBSITE_RUN_FROM_PACKAGE"   = "1",
    "FUNCTIONS_WORKER_RUNTIME"   = "python",
    "SLACK_WEBHOOK_URL__SecretUri" = var.kv_secret_id_slack,
    "ADE_SUBSCRIPTION_ID"        = var.subscription_id
  }, var.app_settings_extra)
}

resource "azurerm_role_assignment" "kv_reader" {
  scope                = var.kv_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_linux_function_app.fn.identity[0].principal_id
}

resource "random_string" "suffix" {
  length = 6
  upper = false
  special = false
}

output "function_app_id"   { value = azurerm_linux_function_app.fn.id }
output "function_app_name" { value = azurerm_linux_function_app.fn.name }
