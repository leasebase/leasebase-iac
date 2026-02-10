################################################################################
# Security Module Outputs
################################################################################

output "s3_endpoint_id" {
  description = "ID of the S3 VPC endpoint"
  value       = aws_vpc_endpoint.s3.id
}

output "dynamodb_endpoint_id" {
  description = "ID of the DynamoDB VPC endpoint"
  value       = aws_vpc_endpoint.dynamodb.id
}

output "ecr_api_endpoint_id" {
  description = "ID of the ECR API VPC endpoint"
  value       = var.enable_ecr_endpoints ? aws_vpc_endpoint.ecr_api[0].id : null
}

output "ecr_dkr_endpoint_id" {
  description = "ID of the ECR DKR VPC endpoint"
  value       = var.enable_ecr_endpoints ? aws_vpc_endpoint.ecr_dkr[0].id : null
}

output "vpc_endpoints_sg_id" {
  description = "ID of the VPC endpoints security group"
  value       = aws_security_group.vpc_endpoints.id
}

output "alb_sg_id" {
  description = "ID of the ALB security group"
  value       = var.create_baseline_sgs ? aws_security_group.alb[0].id : null
}

output "ecs_sg_id" {
  description = "ID of the ECS security group"
  value       = var.create_baseline_sgs ? aws_security_group.ecs[0].id : null
}

output "rds_sg_id" {
  description = "ID of the RDS security group"
  value       = var.create_baseline_sgs ? aws_security_group.rds[0].id : null
}
