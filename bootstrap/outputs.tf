################################################################################
# Bootstrap Module Outputs
################################################################################

output "state_bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  value       = aws_s3_bucket.tfstate.id
}

output "state_bucket_arn" {
  description = "ARN of the S3 bucket for Terraform state"
  value       = aws_s3_bucket.tfstate.arn
}

output "lock_table_name" {
  description = "Name of the DynamoDB table for state locking"
  value       = aws_dynamodb_table.tfstate_lock.name
}

output "lock_table_arn" {
  description = "ARN of the DynamoDB table for state locking"
  value       = aws_dynamodb_table.tfstate_lock.arn
}

output "terraform_provisioner_role_arn" {
  description = "ARN of the IAM role for Terraform provisioning"
  value       = aws_iam_role.terraform_provisioner.arn
}

output "management_account_id" {
  description = "AWS Account ID of the management account"
  value       = data.aws_caller_identity.current.account_id
}

output "aws_region" {
  description = "AWS region where bootstrap resources are deployed"
  value       = data.aws_region.current.name
}

output "backend_config" {
  description = "Backend configuration for environment Terraform"
  value = {
    bucket         = aws_s3_bucket.tfstate.id
    region         = data.aws_region.current.name
    dynamodb_table = aws_dynamodb_table.tfstate_lock.name
    encrypt        = true
  }
}
