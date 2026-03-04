################################################################################
# Lambda Worker Module - LeaseBase v2 (optional)
# Placeholder for lightweight async workers
################################################################################

resource "aws_iam_role" "lambda" {
  count = var.enabled ? 1 : 0

  name = "${var.name_prefix}-lambda-worker"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.common_tags
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  count = var.enabled ? 1 : 0

  role       = aws_iam_role.lambda[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy" "lambda_permissions" {
  count = var.enabled ? 1 : 0

  name = "worker-permissions"
  role = aws_iam_role.lambda[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "kms:Decrypt"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "*"
      }
    ]
  })
}

# Placeholder Lambda (requires actual deployment artifact)
resource "aws_cloudwatch_log_group" "lambda" {
  count = var.enabled ? 1 : 0

  name              = "/aws/lambda/${var.name_prefix}-worker"
  retention_in_days = var.log_retention_days

  tags = var.common_tags
}
