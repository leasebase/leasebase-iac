################################################################################
# Dev Environment Variables
################################################################################

variable "aws_region" {
  description = "AWS region for the dev environment"
  type        = string
  default     = "us-west-2"
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
  description = "Enable NAT Gateway"
  type        = bool
  default     = false
}

################################################################################
# RDS Configuration
################################################################################

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "leasebase"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "leasebase"
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 20
}

################################################################################
# ALB Configuration
################################################################################

variable "acm_certificate_arn" {
  description = "ACM certificate ARN for HTTPS"
  type        = string
  default     = ""
}

################################################################################
# ECS Configuration
################################################################################

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

variable "api_port" {
  description = "API container port"
  type        = number
  default     = 3000
}

variable "api_task_cpu" {
  description = "API task CPU units"
  type        = number
  default     = 256
}

variable "api_task_memory" {
  description = "API task memory in MB"
  type        = number
  default     = 512
}

variable "api_desired_count" {
  description = "Desired number of API tasks"
  type        = number
  default     = 1
}

variable "web_port" {
  description = "Web container port"
  type        = number
  default     = 3000
}

variable "web_task_cpu" {
  description = "Web task CPU units"
  type        = number
  default     = 256
}

variable "web_task_memory" {
  description = "Web task memory in MB"
  type        = number
  default     = 512
}

variable "web_desired_count" {
  description = "Desired number of web tasks"
  type        = number
  default     = 1
}

variable "api_base_url" {
  description = "Base URL for the API"
  type        = string
  default     = ""
}
