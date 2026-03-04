################################################################################
# QA Environment Variables
################################################################################

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

################################################################################
# VPC Variables
################################################################################

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.20.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.20.1.0/24", "10.20.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.20.10.0/24", "10.20.11.0/24"]
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  type        = bool
  default     = false
}

variable "enable_vpc_flow_logs" {
  description = "Enable VPC Flow Logs"
  type        = bool
  default     = false
}

variable "enable_vpc_endpoints" {
  description = "Enable VPC Endpoints (ECR, SSM, CloudWatch Logs)"
  type        = bool
  default     = false
}

################################################################################
# IAM Variables
################################################################################

variable "management_account_id" {
  description = "AWS Account ID that can assume the Terraform access role"
  type        = string
}

variable "terraform_external_id" {
  description = "External ID for assuming the Terraform access role"
  type        = string
  default     = "leasebase-terraform-qa"
}

################################################################################
# Common Tags
################################################################################

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Project   = "LeaseBase"
    ManagedBy = "Terraform"
  }
}
