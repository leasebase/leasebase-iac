output "web_acl_id" {
  description = "WAF Web ACL ID"
  value       = var.enabled ? aws_wafv2_web_acl.main[0].id : ""
}

output "web_acl_arn" {
  description = "WAF Web ACL ARN"
  value       = var.enabled ? aws_wafv2_web_acl.main[0].arn : ""
}
