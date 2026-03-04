################################################################################
# Production Environment Outputs
################################################################################

output "environment" {
  description = "Environment name"
  value       = "prod"
}

output "account_id" {
  description = "AWS Account ID"
  value       = data.aws_caller_identity.current.account_id
}

output "region" {
  description = "AWS Region"
  value       = data.aws_region.current.name
}

################################################################################
# VPC Outputs
################################################################################

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "availability_zones" {
  description = "List of availability zones"
  value       = module.vpc.availability_zones
}

################################################################################
# Security Outputs
################################################################################

output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = module.security.alb_sg_id
}

output "ecs_security_group_id" {
  description = "ID of the ECS security group"
  value       = module.security.ecs_sg_id
}

output "rds_security_group_id" {
  description = "ID of the RDS security group"
  value       = module.security.rds_sg_id
}

################################################################################
# IAM Outputs
################################################################################

output "terraform_access_role_arn" {
  description = "ARN of the Terraform cross-account access role"
  value       = module.iam.terraform_access_role_arn
}

output "ecs_task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  value       = module.iam.ecs_task_execution_role_arn
}

output "ecs_task_role_arn" {
  description = "ARN of the ECS task role"
  value       = module.iam.ecs_task_role_arn
}
