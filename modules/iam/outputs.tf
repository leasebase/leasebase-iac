################################################################################
# IAM Module Outputs
################################################################################

output "terraform_access_role_arn" {
  description = "ARN of the Terraform cross-account access role"
  value       = aws_iam_role.terraform_access.arn
}

output "terraform_access_role_name" {
  description = "Name of the Terraform cross-account access role"
  value       = aws_iam_role.terraform_access.name
}

output "ecs_task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  value       = var.create_ecs_roles ? aws_iam_role.ecs_task_execution[0].arn : null
}

output "ecs_task_execution_role_name" {
  description = "Name of the ECS task execution role"
  value       = var.create_ecs_roles ? aws_iam_role.ecs_task_execution[0].name : null
}

output "ecs_task_role_arn" {
  description = "ARN of the ECS task role"
  value       = var.create_ecs_roles ? aws_iam_role.ecs_task[0].arn : null
}

output "ecs_task_role_name" {
  description = "Name of the ECS task role"
  value       = var.create_ecs_roles ? aws_iam_role.ecs_task[0].name : null
}
