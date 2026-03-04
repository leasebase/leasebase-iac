variable "name_prefix" {
  description = "Prefix for all resource names"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "enabled" {
  description = "Enable WAF"
  type        = bool
  default     = false
}

variable "rate_limit" {
  description = "Rate limit (requests per 5 minutes per IP)"
  type        = number
  default     = 2000
}

variable "common_tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
