# Outputs for Monitoring Module

output "dashboard_name" {
  description = "The name of the CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}

output "alarm_topic_arn" {
  description = "The ARN of the SNS topic for alarms"
  value       = aws_sns_topic.alarms.arn
}

output "log_group_name" {
  description = "The name of the CloudWatch log group for application logs"
  value       = aws_cloudwatch_log_group.application.name
}

output "log_group_arn" {
  description = "The ARN of the CloudWatch log group for application logs"
  value       = aws_cloudwatch_log_group.application.arn
}

output "logs_bucket_name" {
  description = "The name of the S3 bucket for logs"
  value       = aws_s3_bucket.logs.bucket
}

output "logs_bucket_arn" {
  description = "The ARN of the S3 bucket for logs"
  value       = aws_s3_bucket.logs.arn
}

output "logs_export_role_arn" {
  description = "The ARN of the IAM role for CloudWatch Logs to S3 export"
  value       = aws_iam_role.logs_export.arn
}

output "ecs_cpu_alarm_arn" {
  description = "The ARN of the ECS CPU utilization alarm"
  value       = aws_cloudwatch_metric_alarm.ecs_cpu.arn
}

output "ecs_memory_alarm_arn" {
  description = "The ARN of the ECS memory utilization alarm"
  value       = aws_cloudwatch_metric_alarm.ecs_memory.arn
}

output "rds_cpu_alarm_arn" {
  description = "The ARN of the RDS CPU utilization alarm"
  value       = aws_cloudwatch_metric_alarm.rds_cpu.arn
}

output "rds_storage_alarm_arn" {
  description = "The ARN of the RDS free storage space alarm"
  value       = aws_cloudwatch_metric_alarm.rds_storage.arn
}

output "alb_5xx_alarm_arn" {
  description = "The ARN of the ALB 5XX error count alarm"
  value       = aws_cloudwatch_metric_alarm.alb_5xx.arn
}
