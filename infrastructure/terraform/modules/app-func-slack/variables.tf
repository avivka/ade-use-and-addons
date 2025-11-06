variable "name_prefix" {}
variable "location" {}
variable "resource_group_name" {}
variable "kv_id" {}
variable "kv_secret_id_slack" {}
variable "subscription_id" {}
variable "app_settings_extra" { type = map(string) default = {} }
