output "collection_endpoint" {
  description = "OpenSearch collection endpoint"
  value       = var.enabled ? aws_opensearchserverless_collection.main[0].collection_endpoint : ""
}

output "dashboard_endpoint" {
  description = "OpenSearch dashboard endpoint"
  value       = var.enabled ? aws_opensearchserverless_collection.main[0].dashboard_endpoint : ""
}
