variable "name_prefix" {
  description = "Prefix for all resource names"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "archive_retention_days" {
  description = "EventBridge archive retention in days"
  type        = number
  default     = 14
}

variable "kms_key_id" {
  description = "KMS key ID for SQS encryption"
  type        = string
  default     = ""
}

variable "common_tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
