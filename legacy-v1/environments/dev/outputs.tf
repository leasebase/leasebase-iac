################################################################################
# Dev Environment Outputs
################################################################################

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.common.vpc_id
}

output "ecr_api_repository_url" {
  description = "ECR repository URL for API"
  value       = module.common.ecr_api_repository_url
}

output "ecr_web_repository_url" {
  description = "ECR repository URL for web"
  value       = module.common.ecr_web_repository_url
}

output "alb_dns_name" {
  description = "DNS name of the ALB"
  value       = module.common.alb_dns_name
}

output "rds_endpoint" {
  description = "RDS endpoint"
  value       = module.common.rds_endpoint
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = module.common.ecs_cluster_name
}

output "ecs_api_service_name" {
  description = "ECS API service name"
  value       = module.common.ecs_api_service_name
}

output "ecs_web_service_name" {
  description = "ECS web service name"
  value       = module.common.ecs_web_service_name
}
