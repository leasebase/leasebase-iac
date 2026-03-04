################################################################################
# Production Environment Variables
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
  default     = "10.40.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b", "us-west-2c"] # 3 AZs for prod
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.40.1.0/24", "10.40.2.0/24", "10.40.3.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.40.10.0/24", "10.40.11.0/24", "10.40.12.0/24"]
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  type        = bool
  default     = true # Always enabled for prod
}

variable "enable_vpc_flow_logs" {
  description = "Enable VPC Flow Logs"
  type        = bool
  default     = true # Always enabled for prod (compliance/security)
}

variable "enable_vpc_endpoints" {
  description = "Enable VPC Endpoints (ECR, SSM, CloudWatch Logs)"
  type        = bool
  default     = true # Recommended for prod security
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
  default     = "leasebase-terraform-prod"
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
