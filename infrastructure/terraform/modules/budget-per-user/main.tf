variable "user_upn" {}
variable "subscription_id" {}
variable "action_group_id" {}

resource "azurerm_consumption_budget_subscription" "user_budget" {
  name            = replace("${var.user_upn}-200", "@", "-")
  subscription_id = var.subscription_id
  amount          = 200
  time_grain      = "Monthly"

  time_period {
    start_date = formatdate("YYYY-MM-01'T'00:00:00Z", timestamp())
    end_date   = "2030-01-01T00:00:00Z"
  }

  filter {
    tags {
      name   = "ade:userUpn"
      values = [var.user_upn]
    }
  }

  notification { enabled = true threshold = 80.0 operator = "EqualTo" contact_groups = [var.action_group_id] }
  notification { enabled = true threshold = 90.0 operator = "EqualTo" contact_groups = [var.action_group_id] }
  notification { enabled = true threshold = 95.0 operator = "EqualTo" contact_groups = [var.action_group_id] }
  notification { enabled = true threshold = 100.0 operator = "EqualTo" contact_groups = [var.action_group_id] }
}
