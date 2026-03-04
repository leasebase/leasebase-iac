################################################################################
# Common Module Variables
################################################################################

variable "environment" {
  description = "Environment name (dev, qa, uat, prod)"
  type        = string
}

################################################################################
# VPC Configuration
################################################################################

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_count" {
  description = "Number of availability zones to use"
  type        = number
  default     = 2
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnet internet access"
  type        = bool
  default     = false
}

variable "single_nat_gateway" {
  description = "Use a single NAT Gateway (cost savings for non-prod)"
  type        = bool
  default     = true
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

variable "db_engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "15.4"
}

variable "db_allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 20
}

variable "db_max_allocated_storage" {
  description = "Maximum allocated storage in GB for autoscaling"
  type        = number
  default     = 100
}

variable "db_backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7
}

variable "db_backup_window" {
  description = "Preferred backup window"
  type        = string
  default     = "03:00-04:00"
}

variable "db_maintenance_window" {
  description = "Preferred maintenance window"
  type        = string
  default     = "Mon:04:00-Mon:05:00"
}

variable "db_skip_final_snapshot" {
  description = "Skip final snapshot when deleting"
  type        = bool
  default     = false
}

variable "db_deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = true
}

################################################################################
# ALB Configuration
################################################################################

variable "alb_deletion_protection" {
  description = "Enable ALB deletion protection"
  type        = bool
  default     = false
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN for HTTPS listener"
  type        = string
  default     = ""
}

################################################################################
# ECS Configuration
################################################################################

variable "enable_container_insights" {
  description = "Enable CloudWatch Container Insights"
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

################################################################################
# API Service Configuration
################################################################################

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

variable "api_container_image" {
  description = "API container image (leave empty to use ECR)"
  type        = string
  default     = ""
}

variable "api_desired_count" {
  description = "Desired number of API tasks"
  type        = number
  default     = 1
}

################################################################################
# Web Service Configuration
################################################################################

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

variable "web_container_image" {
  description = "Web container image (leave empty to use ECR)"
  type        = string
  default     = ""
}

variable "web_desired_count" {
  description = "Desired number of web tasks"
  type        = number
  default     = 1
}

variable "api_base_url" {
  description = "Base URL for the API (used by web frontend)"
  type        = string
  default     = ""
}

################################################################################
# Storage Configuration
################################################################################

variable "enable_cloudfront" {
  description = "Enable CloudFront distribution for static assets"
  type        = bool
  default     = false
}
