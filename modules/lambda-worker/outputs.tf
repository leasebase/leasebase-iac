output "role_arn" {
  description = "Lambda execution role ARN"
  value       = var.enabled ? aws_iam_role.lambda[0].arn : ""
}

output "log_group_name" {
  description = "Lambda CloudWatch log group name"
  value       = var.enabled ? aws_cloudwatch_log_group.lambda[0].name : ""
}
