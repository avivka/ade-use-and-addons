terraform {
  required_version = ">= 1.7.0"
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = ">= 3.118.0" }
    random  = { source = "hashicorp/random", version = ">= 3.6.0" }
  }
}

provider "azurerm" { features {} }

locals {
  name_prefix = var.name_prefix
  location    = var.location
}

resource "azurerm_resource_group" "rg" {
  name     = "${local.name_prefix}-rg"
  location = local.location
}

module "kv" {
  source              = "../modules/key-vault"
  name_prefix         = local.name_prefix
  location            = local.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Slack webhook secret in KV (optional: you can import later via CLI)
resource "azurerm_key_vault_secret" "slack_hook" {
  name         = "SLACK-WEBHOOK-URL"
  value        = var.slack_webhook_url
  key_vault_id = module.kv.id
}

module "app_func" {
  source                = "../modules/app-func-slack"
  name_prefix           = local.name_prefix
  location              = local.location
  resource_group_name   = azurerm_resource_group.rg.name
  kv_id                 = module.kv.id
  kv_secret_id_slack    = azurerm_key_vault_secret.slack_hook.id
  subscription_id       = var.subscription_id
  app_settings_extra    = var.function_app_settings
}

module "action_group" {
  source               = "../modules/action-group-budget-to-func"
  name_prefix          = local.name_prefix
  resource_group_name  = azurerm_resource_group.rg.name
  function_app_id      = module.app_func.function_app_id
  function_name        = "budgetAlertHandler"
}

# Example user budgets. Provide a list of UPNs in var.user_upns
module "budget_per_user" {
  source               = "../modules/budget-per-user"
  for_each             = toset(var.user_upns)
  user_upn             = each.key
  subscription_id      = var.subscription_id
  action_group_id      = module.action_group.id
}

# Policy: require ade:expiresOn on RGs
module "policy_expiration" {
  source          = "../modules/policy-expiration-required"
  assignment_scope = "/subscriptions/${var.subscription_id}"
}
