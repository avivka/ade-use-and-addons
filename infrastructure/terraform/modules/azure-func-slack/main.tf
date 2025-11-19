# app service plan (consumption)
resource "azurerm_linux_function_app" "fn" {
  name                       = "${var.name}-fn"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  storage_account_name       = azurerm_storage_account.func.name
  storage_account_access_key = azurerm_storage_account.func.primary_access_key
  service_plan_id            = azurerm_service_plan.plan.id
  https_only                 = true

  identity {
    type = "SystemAssigned"
  }

  site_config {
    application_insights_key = azurerm_application_insights.ai.instrumentation_key
    ftps_state               = "Disabled"
    health_check_path        = "/api/healthz"
  }

  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE" = "1"
    "SLACK_WEBHOOK_URL__SecretUri" = azurerm_key_vault_secret.slack_hook.id
    "ADE_SUBSCRIPTION_ID" = var.subscription_id
  }

  auth_settings_v2 {
    auth_enabled           = true
    require_authentication = true
    required_authentication_provider = "azureactivedirectory"
    login {
      token_store_enabled = true
    }
    identity_providers {
      azure_active_directory {
        enabled                         = true
        # allow Action Group (first-party) to call via AAD; audience is the app's default
        login_parameters = []
      }
    }
    http_settings {
      routes {
        unauthenticated_action = "Return401"
      }
    }
  }
}

# KV access
resource "azurerm_role_assignment" "kv_reader" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_linux_function_app.fn.identity[0].principal_id
}
