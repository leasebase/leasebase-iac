variable "name_prefix" {
  description = "Prefix for all resource names"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "kms_key_id" {
  description = "KMS key ID for encryption"
  type        = string
  default     = ""
}

variable "queues" {
  description = "Map of queue configurations"
  type        = map(map(any))
  default = {
    notifications       = {}
    document-processing = { visibility_timeout = 600 }
    reporting-jobs      = { visibility_timeout = 900 }
  }
}

variable "common_tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
