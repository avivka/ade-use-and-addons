# ==============================================================================
# LOCALS
# Logic App Slack Integration Module
# ==============================================================================

locals {
  # ==============================================================================
  # RESOURCE NAMING
  # ==============================================================================
  
  # Resource naming conventions following Azure best practices
  random_suffix = random_string.suffix.result
  
  # Core resource names
  key_vault_name       = "kv-${var.logic_app_name}-${local.random_suffix}"
  storage_account_name = "st${replace(var.logic_app_name, "-", "")}${random_string.storage_suffix.result}"
  app_insights_name    = "ai-${var.logic_app_name}-${local.random_suffix}"
  log_analytics_name   = "law-${var.logic_app_name}-${local.random_suffix}"
  event_grid_topic_name = "egt-${var.event_grid_topic_name}-${local.random_suffix}"
  
  # Logic App specific names
  logic_app_standard_name = "las-${var.logic_app_name}-${local.random_suffix}"
  service_plan_name      = "asp-${var.logic_app_name}-${local.random_suffix}"
  
  # ==============================================================================
  # TAGGING STRATEGY
  # ==============================================================================
  
  # Common tags applied to all resources
  common_tags = merge({
    # Core identification tags
    "purpose"           = "ade-slack-integration"
    "environment"       = var.environment_type
    "cost-center"       = var.cost_center
    "logic-app-name"    = var.logic_app_name
    
    # Operational tags
    "managed-by"        = "terraform"
    "created-date"      = formatdate("YYYY-MM-DD", timestamp())
    "deployment-id"     = random_uuid.deployment_id.result
    
    # Integration tags
    "integration-type"  = "event-driven"
    "notification-type" = "slack"
    "event-source"      = "ade-events"
    
    # Compliance tags
    "data-classification" = "internal"
    "backup-required"     = "false"
    "monitoring-required" = "true"
    
    # Cost management tags
    "auto-shutdown"      = "disabled"
    "resource-category"  = "integration"
  }, var.additional_tags)
  
  # ==============================================================================
  # SECURITY CONFIGURATION
  # ==============================================================================
  
  # Key Vault access policies and security settings
  key_vault_security_config = {
    enable_rbac_authorization = var.enable_rbac_authorization
    enable_soft_delete       = true
    soft_delete_retention    = var.soft_delete_retention_days
    enable_purge_protection  = var.enable_purge_protection
    default_action          = "Allow"
    bypass                  = "AzureServices"
  }
  
  # Storage account security settings
  storage_security_config = {
    allow_nested_items_to_be_public = false
    https_traffic_only_enabled      = true
    min_tls_version                 = "TLS1_2"
    public_network_access_enabled   = var.allow_public_access
    default_action                  = var.allow_public_access ? "Allow" : "Deny"
    bypass                         = ["AzureServices", "Logging", "Metrics"]
  }
  
  # ==============================================================================
  # LOGIC APP CONFIGURATION
  # ==============================================================================
  
  # Logic App workflow definition for Slack notifications
  workflow_definition = {
    "$schema" = "https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#"
    contentVersion = "1.0.0.0"
    parameters = {
      slackWebhookUrl = {
        type = "string"
        metadata = {
          description = "Slack webhook URL from Key Vault"
        }
      }
    }
    triggers = {
      "When_ADE_Event_Received" = {
        type = "ApiConnection"
        inputs = {
          host = {
            connection = {
              name = "@parameters('$connections')['azureeventgrid']['connectionId']"
            }
          }
          method = "post"
          path = "/eventSubscriptions"
          queries = {
            subscriptionName = "ade-slack-subscription"
          }
        }
        splitOn = "@triggerBody()"
      }
    }
    actions = {
      "Parse_Event_Data" = {
        type = "ParseJson"
        inputs = {
          content = "@triggerBody()"
          schema = {
            type = "object"
            properties = {
              id = { type = "string" }
              subject = { type = "string" }
              dataVersion = { type = "string" }
              eventType = { type = "string" }
              data = {
                type = "object"
                properties = {
                  environmentName = { type = "string" }
                  userEmail = { type = "string" }
                  expirationDate = { type = "string" }
                  budgetAmount = { type = "number" }
                  currentCost = { type = "number" }
                }
              }
              eventTime = { type = "string" }
            }
          }
        }
        runAfter = {}
      }
      "Format_Slack_Message" = {
        type = "Compose"
        inputs = "@concat('🚨 ADE Event Alert\\n\\n', '**Event Type:** ', body('Parse_Event_Data')?['eventType'], '\\n', '**Environment:** ', body('Parse_Event_Data')?['data']?['environmentName'], '\\n', '**User:** ', body('Parse_Event_Data')?['data']?['userEmail'], '\\n', '**Time:** ', body('Parse_Event_Data')?['eventTime'], if(contains(body('Parse_Event_Data')?['data'], 'currentCost'), concat('\\n', '**Current Cost:** $', string(body('Parse_Event_Data')?['data']?['currentCost'])), ''), if(contains(body('Parse_Event_Data')?['data'], 'budgetAmount'), concat('\\n', '**Budget:** $', string(body('Parse_Event_Data')?['data']?['budgetAmount'])), ''), if(contains(body('Parse_Event_Data')?['data'], 'expirationDate'), concat('\\n', '**Expiration:** ', body('Parse_Event_Data')?['data']?['expirationDate']), ''))"
        runAfter = {
          "Parse_Event_Data" = ["Succeeded"]
        }
      }
      "Send_to_Slack" = {
        type = "Http"
        inputs = {
          method = "POST"
          uri = "@parameters('slackWebhookUrl')"
          headers = {
            "Content-Type" = "application/json"
          }
          body = {
            text = "@outputs('Format_Slack_Message')"
            username = "ADE Bot"
            icon_emoji = ":warning:"
            channel = "#ade-alerts"
          }
        }
        runAfter = {
          "Format_Slack_Message" = ["Succeeded"]
        }
      }
      "Log_Event" = {
        type = "Http"
        inputs = {
          method = "POST"
          uri = "https://@{variables('logAnalyticsWorkspaceId')}.ods.opinsights.azure.com/api/logs?api-version=2016-04-01"
          headers = {
            "Content-Type" = "application/json"
            "Log-Type" = "ADEEvent"
          }
          body = {
            event = "@body('Parse_Event_Data')"
            processedTime = "@utcNow()"
            slackDelivered = "@if(equals(outputs('Send_to_Slack')['statusCode'], 200), true, false)"
          }
        }
        runAfter = {
          "Send_to_Slack" = ["Succeeded", "Failed"]
        }
      }
    }
    outputs = {}
  }
  
  # ==============================================================================
  # EVENT GRID CONFIGURATION
  # ==============================================================================
  
  # Event Grid event subscription filters
  event_subscription_config = {
    included_event_types = [
      "Microsoft.ADE.EnvironmentCreated",
      "Microsoft.ADE.EnvironmentDeleted", 
      "Microsoft.ADE.EnvironmentExpiring",
      "Microsoft.ADE.BudgetThresholdExceeded",
      "Microsoft.ADE.BudgetExceeded"
    ]
    subject_filters = {
      begins_with = ["/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.ade_resource_group_name}"]
      ends_with   = []
    }
    advanced_filters = [
      {
        key      = "data.environmentType"
        values   = var.event_filter_settings.environment_types
        operator = "StringIn"
      }
    ]
  }
  
  # ==============================================================================
  # APPLICATION INSIGHTS CONFIGURATION
  # ==============================================================================
  
  # Application Insights configuration for monitoring
  app_insights_config = {
    application_type                = "web"
    retention_in_days              = var.log_retention_days
    daily_data_cap_in_gb           = 1
    daily_data_cap_notifications_disabled = false
    sampling_percentage            = 100
    disable_ip_masking            = false
  }
  
  # ==============================================================================
  # SERVICE PLAN CONFIGURATION
  # ==============================================================================
  
  # App Service Plan configuration for Logic App Standard
  service_plan_config = {
    os_type  = "Windows"
    sku_name = var.environment_type == "production" ? "WS1" : "WS1"  # Workflow Standard
  }
  
  # ==============================================================================
  # COMPUTED VALUES
  # ==============================================================================
  
  # Current timestamp for tracking
  timestamp = timestamp()
  
  # Key Vault secret names
  secret_names = {
    slack_webhook = "slack-webhook-url"
    storage_key   = "storage-connection-string"
  }
  
  # Connection strings and endpoints
  log_analytics_workspace_id = "placeholder-for-workspace-id"  # Will be replaced with actual ID
}