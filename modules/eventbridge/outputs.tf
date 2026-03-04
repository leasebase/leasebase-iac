output "event_bus_name" {
  description = "EventBridge bus name"
  value       = aws_cloudwatch_event_bus.main.name
}

output "event_bus_arn" {
  description = "EventBridge bus ARN"
  value       = aws_cloudwatch_event_bus.main.arn
}

output "dlq_arn" {
  description = "Dead-letter queue ARN"
  value       = aws_sqs_queue.dlq.arn
}
