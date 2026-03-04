################################################################################
# QA Environment - LeaseBase Foundation
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
      Environment = "qa"
      ManagedBy   = "Terraform"
    }
  }
}

################################################################################
# Data Sources
################################################################################

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

################################################################################
# VPC Module
################################################################################

module "vpc" {
  source = "../../modules/vpc"

  name_prefix        = "leasebase-qa"
  environment        = "qa"
  vpc_cidr           = var.vpc_cidr
  az_count           = 2
  enable_nat_gateway = var.enable_nat_gateway
  single_nat_gateway = true
  enable_flow_logs   = var.enable_vpc_flow_logs
}

################################################################################
# Security Module
################################################################################

module "security" {
  source = "../../modules/security"

  name_prefix        = "leasebase-qa"
  environment        = "qa"
  vpc_id             = module.vpc.vpc_id
  vpc_cidr           = module.vpc.vpc_cidr
  private_subnet_ids = module.vpc.private_subnet_ids
  route_table_ids    = module.vpc.private_route_table_ids

  enable_ecr_endpoints = var.enable_vpc_endpoints
  enable_ssm_endpoints = var.enable_vpc_endpoints
  enable_logs_endpoint = var.enable_vpc_endpoints
}

################################################################################
# IAM Module
################################################################################

module "iam" {
  source = "../../modules/iam"

  name_prefix           = "leasebase-qa"
  environment           = "qa"
  management_account_id = var.management_account_id
  external_id           = var.terraform_external_id
}
