################################################################################
# Dev Environment - LeaseBase
################################################################################

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    # Configure via backend.hcl:
    # terraform init -backend-config=backend.hcl
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "LeaseBase"
      Environment = "dev"
      ManagedBy   = "Terraform"
    }
  }
}

################################################################################
# Common Module
################################################################################

module "common" {
  source = "../../envs/common"

  environment = "dev"

  # VPC Configuration
  vpc_cidr           = var.vpc_cidr
  az_count           = var.az_count
  enable_nat_gateway = var.enable_nat_gateway
  single_nat_gateway = true

  # RDS Configuration
  db_name                  = var.db_name
  db_username              = var.db_username
  db_password              = var.db_password
  db_instance_class        = var.db_instance_class
  db_allocated_storage     = var.db_allocated_storage
  db_skip_final_snapshot   = true
  db_deletion_protection   = false

  # ALB Configuration
  acm_certificate_arn = var.acm_certificate_arn

  # ECS Configuration
  log_retention_days = var.log_retention_days

  # API Service
  api_port          = var.api_port
  api_task_cpu      = var.api_task_cpu
  api_task_memory   = var.api_task_memory
  api_desired_count = var.api_desired_count

  # Web Service
  web_port          = var.web_port
  web_task_cpu      = var.web_task_cpu
  web_task_memory   = var.web_task_memory
  web_desired_count = var.web_desired_count
  api_base_url      = var.api_base_url
}
