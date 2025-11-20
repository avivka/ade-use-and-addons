variable "name_prefix" { type = string }
variable "location"    { type = string  default = "westeurope" }
variable "subscription_id" { type = string }
variable "slack_webhook_url" { type = string  default = "" } # can be empty, set later via script
variable "user_upns" { type = list(string) default = [] }
variable "function_app_settings" {
  type    = map(string)
  default = {}
}
