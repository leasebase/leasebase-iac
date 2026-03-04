################################################################################
# Observability Module - LeaseBase v2
# CloudWatch dashboard, alarms, SNS topic
################################################################################

# SNS topic for alarms
resource "aws_sns_topic" "alarms" {
  name = "${var.name_prefix}-alarms"

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-alarms"
  })
}

# ECS CPU utilization alarm (per-cluster)
resource "aws_cloudwatch_metric_alarm" "ecs_cpu_high" {
  alarm_name          = "${var.name_prefix}-ecs-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "ECS cluster CPU > 80%"
  alarm_actions       = [aws_sns_topic.alarms.arn]

  dimensions = {
    ClusterName = var.ecs_cluster_name
  }

  tags = var.common_tags
}

# ECS Memory utilization alarm
resource "aws_cloudwatch_metric_alarm" "ecs_memory_high" {
  alarm_name          = "${var.name_prefix}-ecs-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 85
  alarm_description   = "ECS cluster memory > 85%"
  alarm_actions       = [aws_sns_topic.alarms.arn]

  dimensions = {
    ClusterName = var.ecs_cluster_name
  }

  tags = var.common_tags
}

# ALB 5xx errors alarm
resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  count = var.alb_arn_suffix != "" ? 1 : 0

  alarm_name          = "${var.name_prefix}-alb-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "ALB 5xx errors > 10 in 5 minutes"
  alarm_actions       = [aws_sns_topic.alarms.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }

  tags = var.common_tags
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.name_prefix}-overview"

  dashboard_body = jsonencode({
    widgets = concat(
      [
        {
          type   = "metric"
          x      = 0
          y      = 0
          width  = 12
          height = 6
          properties = {
            title  = "ECS CPU Utilization"
            region = var.aws_region
            metrics = [
              ["AWS/ECS", "CPUUtilization", "ClusterName", var.ecs_cluster_name, { stat = "Average" }]
            ]
            period = 300
            view   = "timeSeries"
          }
        },
        {
          type   = "metric"
          x      = 12
          y      = 0
          width  = 12
          height = 6
          properties = {
            title  = "ECS Memory Utilization"
            region = var.aws_region
            metrics = [
              ["AWS/ECS", "MemoryUtilization", "ClusterName", var.ecs_cluster_name, { stat = "Average" }]
            ]
            period = 300
            view   = "timeSeries"
          }
        }
      ],
      [for i, name in var.service_names : {
        type   = "log"
        x      = (i % 2) * 12
        y      = 6 + floor(i / 2) * 6
        width  = 12
        height = 6
        properties = {
          title  = "Logs: ${name}"
          region = var.aws_region
          query  = "SOURCE '/ecs/${name}' | fields @timestamp, @message | sort @timestamp desc | limit 50"
        }
      }]
    )
  })
}
