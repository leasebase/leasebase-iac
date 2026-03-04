################################################################################
# Security Module Variables
################################################################################

variable "name_prefix" {
  description = "Prefix for resource names (e.g., leasebase-dev)"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, qa, uat, prod)"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for interface endpoints"
  type        = list(string)
  default     = []
}

variable "route_table_ids" {
  description = "List of route table IDs for gateway endpoints"
  type        = list(string)
}

variable "enable_ecr_endpoints" {
  description = "Enable ECR VPC endpoints (costs money)"
  type        = bool
  default     = false
}

variable "enable_ssm_endpoints" {
  description = "Enable SSM VPC endpoints (costs money)"
  type        = bool
  default     = false
}

variable "enable_logs_endpoint" {
  description = "Enable CloudWatch Logs VPC endpoint (costs money)"
  type        = bool
  default     = false
}

variable "create_baseline_sgs" {
  description = "Create baseline security groups (ALB, ECS, RDS)"
  type        = bool
  default     = true
}
