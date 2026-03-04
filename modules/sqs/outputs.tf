output "queue_urls" {
  description = "Map of queue names to URLs"
  value       = { for k, v in aws_sqs_queue.main : k => v.url }
}

output "queue_arns" {
  description = "Map of queue names to ARNs"
  value       = { for k, v in aws_sqs_queue.main : k => v.arn }
}

output "dlq_urls" {
  description = "Map of DLQ names to URLs"
  value       = { for k, v in aws_sqs_queue.dlq : k => v.url }
}

output "dlq_arns" {
  description = "Map of DLQ names to ARNs"
  value       = { for k, v in aws_sqs_queue.dlq : k => v.arn }
}
