################################################################################
# IAM Module Variables
################################################################################

variable "name_prefix" {
  description = "Prefix for resource names (e.g., leasebase-dev)"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, qa, uat, prod)"
  type        = string
}

variable "management_account_id" {
  description = "AWS Account ID of the management account for cross-account access"
  type        = string
}

variable "external_id" {
  description = "External ID for cross-account role assumption (security best practice)"
  type        = string
  default     = "leasebase-terraform"
}

variable "create_ecs_roles" {
  description = "Create ECS task roles (set to true when deploying application infrastructure)"
  type        = bool
  default     = true
}
