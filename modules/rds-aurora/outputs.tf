output "cluster_endpoint" {
  description = "Aurora cluster endpoint"
  value       = aws_rds_cluster.main.endpoint
}

output "reader_endpoint" {
  description = "Aurora reader endpoint"
  value       = aws_rds_cluster.main.reader_endpoint
}

output "port" {
  description = "Aurora port"
  value       = aws_rds_cluster.main.port
}

output "database_name" {
  description = "Database name"
  value       = aws_rds_cluster.main.database_name
}

output "secret_arn" {
  description = "Secrets Manager secret ARN for DB credentials"
  value       = aws_secretsmanager_secret.db.arn
}

output "security_group_id" {
  description = "Database security group ID"
  value       = aws_security_group.db.id
}

output "cluster_identifier" {
  description = "Aurora cluster identifier"
  value       = aws_rds_cluster.main.cluster_identifier
}
