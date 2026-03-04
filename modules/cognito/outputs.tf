output "user_pool_id" {
  description = "Cognito User Pool ID"
  value       = aws_cognito_user_pool.main.id
}

output "user_pool_arn" {
  description = "Cognito User Pool ARN"
  value       = aws_cognito_user_pool.main.arn
}

output "user_pool_endpoint" {
  description = "Cognito User Pool endpoint"
  value       = aws_cognito_user_pool.main.endpoint
}

output "web_client_id" {
  description = "Web app client ID"
  value       = aws_cognito_user_pool_client.web.id
}

output "mobile_client_id" {
  description = "Mobile app client ID"
  value       = aws_cognito_user_pool_client.mobile.id
}

output "user_pool_domain" {
  description = "Cognito domain"
  value       = aws_cognito_user_pool_domain.main.domain
}
