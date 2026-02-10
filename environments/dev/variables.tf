################################################################################
# Dev Environment Variables
################################################################################

variable "aws_region" {
  description = "AWS region for the dev environment"
  type        = string
  default     = "us-west-2"
}

variable "account_id" {
  description = "AWS Account ID for the dev environment"
  type        = string
  default     = ""
}

variable "management_account_id" {
  description = "AWS Account ID of the management account"
  type        = string
}

variable "external_id" {
  description = "External ID for cross-account role assumption"
  type        = string
  default     = "leasebase-terraform"
}

################################################################################
# VPC Configuration
################################################################################

variable "vpc_cidr" {
  description = "CIDR block for the dev VPC"
  type        = string
  default     = "10.10.0.0/16"
}

variable "az_count" {
  description = "Number of availability zones"
  type        = number
  default     = 2
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway (costs money)"
  type        = bool
  default     = false
}

variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs"
  type        = bool
  default     = false
}

################################################################################
# Security Configuration
################################################################################

variable "enable_ecr_endpoints" {
  description = "Enable ECR VPC endpoints"
  type        = bool
  default     = false
}

variable "enable_ssm_endpoints" {
  description = "Enable SSM VPC endpoints"
  type        = bool
  default     = false
}

variable "enable_logs_endpoint" {
  description = "Enable CloudWatch Logs VPC endpoint"
  type        = bool
  default     = false
}

variable "create_baseline_sgs" {
  description = "Create baseline security groups"
  type        = bool
  default     = true
}

variable "create_ecs_roles" {
  description = "Create ECS IAM roles"
  type        = bool
  default     = true
}
