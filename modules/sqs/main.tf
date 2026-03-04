################################################################################
# SQS Module - LeaseBase v2
# Creates SQS queues with dead-letter queues
################################################################################

resource "aws_sqs_queue" "dlq" {
  for_each = var.queues

  name                      = "${var.name_prefix}-${each.key}-dlq"
  message_retention_seconds = 1209600 # 14 days
  kms_master_key_id         = var.kms_key_id

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-${each.key}-dlq"
  })
}

resource "aws_sqs_queue" "main" {
  for_each = var.queues

  name                       = "${var.name_prefix}-${each.key}"
  visibility_timeout_seconds = lookup(each.value, "visibility_timeout", 300)
  message_retention_seconds  = lookup(each.value, "retention_seconds", 345600)
  kms_master_key_id          = var.kms_key_id

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq[each.key].arn
    maxReceiveCount     = lookup(each.value, "max_receive_count", 3)
  })

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-${each.key}"
  })
}
