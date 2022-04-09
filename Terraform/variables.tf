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
