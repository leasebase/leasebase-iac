################################################################################
# LeaseBase IAM Module
# Creates IAM roles for cross-account access and baseline security
################################################################################

data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id

  common_tags = {
    Project     = "leasebase"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

################################################################################
# Terraform Access Role
# This role is assumed by Terraform from the management account
################################################################################

resource "aws_iam_role" "terraform_access" {
  name = "leasebase-terraform-access"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.management_account_id}:root"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = var.external_id
          }
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name        = "leasebase-terraform-access"
    Description = "Role for Terraform cross-account access from management account"
  })
}

# Attach AdministratorAccess for Terraform provisioning
# In production, consider using more restrictive permissions
resource "aws_iam_role_policy_attachment" "terraform_admin" {
  role       = aws_iam_role.terraform_access.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

################################################################################
# ECS Task Execution Role
# Used by ECS to pull images and write logs
################################################################################

resource "aws_iam_role" "ecs_task_execution" {
  count = var.create_ecs_roles ? 1 : 0

  name = "${var.name_prefix}-ecs-task-execution"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-ecs-task-execution"
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  count = var.create_ecs_roles ? 1 : 0

  role       = aws_iam_role.ecs_task_execution[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Additional policy for Secrets Manager access
resource "aws_iam_role_policy" "ecs_secrets_access" {
  count = var.create_ecs_roles ? 1 : 0

  name = "secrets-access"
  role = aws_iam_role.ecs_task_execution[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = "arn:aws:secretsmanager:*:${local.account_id}:secret:leasebase/${var.environment}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "secretsmanager.*.amazonaws.com"
          }
        }
      }
    ]
  })
}

################################################################################
# ECS Task Role
# Used by running containers for AWS API access
################################################################################

resource "aws_iam_role" "ecs_task" {
  count = var.create_ecs_roles ? 1 : 0

  name = "${var.name_prefix}-ecs-task"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-ecs-task"
  })
}

# S3 access for documents bucket
resource "aws_iam_role_policy" "ecs_s3_access" {
  count = var.create_ecs_roles ? 1 : 0

  name = "s3-access"
  role = aws_iam_role.ecs_task[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::leasebase-${var.environment}-*",
          "arn:aws:s3:::leasebase-${var.environment}-*/*"
        ]
      }
    ]
  })
}

# SES access for email
resource "aws_iam_role_policy" "ecs_ses_access" {
  count = var.create_ecs_roles ? 1 : 0

  name = "ses-access"
  role = aws_iam_role.ecs_task[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail"
        ]
        Resource = "*"
      }
    ]
  })
}

# Cognito access
resource "aws_iam_role_policy" "ecs_cognito_access" {
  count = var.create_ecs_roles ? 1 : 0

  name = "cognito-access"
  role = aws_iam_role.ecs_task[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cognito-idp:AdminCreateUser",
          "cognito-idp:AdminDeleteUser",
          "cognito-idp:AdminGetUser",
          "cognito-idp:AdminUpdateUserAttributes",
          "cognito-idp:AdminSetUserPassword",
          "cognito-idp:ListUsers"
        ]
        Resource = "arn:aws:cognito-idp:*:${local.account_id}:userpool/*"
      }
    ]
  })
}
