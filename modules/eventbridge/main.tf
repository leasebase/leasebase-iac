################################################################################
# EventBridge Module - LeaseBase v2
################################################################################

resource "aws_cloudwatch_event_bus" "main" {
  name = "${var.name_prefix}-bus"

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-bus"
  })
}

# Archive for replay capability
resource "aws_cloudwatch_event_archive" "main" {
  name             = "${var.name_prefix}-archive"
  event_source_arn = aws_cloudwatch_event_bus.main.arn
  retention_days   = var.archive_retention_days
}

# Dead-letter queue for failed events
resource "aws_sqs_queue" "dlq" {
  name = "${var.name_prefix}-eventbridge-dlq"

  message_retention_seconds = 1209600 # 14 days
  kms_master_key_id         = var.kms_key_id

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-eventbridge-dlq"
  })
}
