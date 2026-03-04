variable "name_prefix" {
  description = "Prefix for all resource names"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key ARN for encryption"
  type        = string
}

variable "force_destroy" {
  description = "Allow force destroy of bucket"
  type        = bool
  default     = false
}

variable "cors_allowed_origins" {
  description = "CORS allowed origins"
  type        = list(string)
  default     = ["*"]
}

variable "common_tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
