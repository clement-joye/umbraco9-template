variable "sku_tier" {
  description = "Specifies the plan's pricing tier."
  type        = string
  default     = "Basic"
}

variable "sku_size" {
  description = "Specifies the plan's instance size."
  type        = string
  default     = "B1"
}

variable "azure_resource_group" {
  type  = string
}

variable "azure_acronym" {
  type  = string
}

variable "environment" {
  type  = string
}

variable "sql_username" {
  type = string
}

variable "sql_password" {
  type = string
  sensitive = true
}