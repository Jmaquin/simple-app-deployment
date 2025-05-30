mock_provider "aws" {
  mock_resource "aws_iam_role" {
    defaults = {
      arn  = "arn:aws:iam::123456789012:role/test-role"
      name = "test-role"
    }
  }

  mock_resource "aws_iam_policy" {
    defaults = {
      arn = "arn:aws:iam::123456789012:policy/MyCustomPolicy"
    }
  }

  mock_resource "aws_s3_bucket" {
    defaults = {
      arn = "arn:aws:s3:::BUCKET-NAME"
    }
  }

  mock_resource "aws_sns_topic" {
    defaults = {
      arn = "arn:aws:sns:eu-west-3:123456789012:my-notification-topic"
    }
  }
}

run "cloudwatch_dashboard" {
  command = apply

  variables {
    environment  = "test"
    project_name = "test-project"
    vpc_id       = "vpc-12345678"
    region       = "us-east-1"
    alarm_email  = "test@example.com"
  }

  # Verify that the CloudWatch dashboard is created with the correct name
  assert {
    condition     = aws_cloudwatch_dashboard.main.dashboard_name == "test-project-test-dashboard"
    error_message = "CloudWatch dashboard name does not match expected value"
  }

  # Verify that the dashboard body is valid JSON
  assert {
    condition     = can(jsondecode(aws_cloudwatch_dashboard.main.dashboard_body))
    error_message = "Dashboard body is not valid JSON"
  }

  # Verify that the dashboard contains the expected widgets
  assert {
    condition     = length(jsondecode(aws_cloudwatch_dashboard.main.dashboard_body).widgets) >= 6
    error_message = "Dashboard does not contain the expected number of widgets"
  }

  # Verify that the dashboard has the correct region
  assert {
    condition = contains([
      for widget in jsondecode(aws_cloudwatch_dashboard.main.dashboard_body).widgets : widget.properties.region
    ], "us-east-1")
    error_message = "Dashboard widgets do not have the correct region"
  }
}

run "cloudwatch_alarms" {
  variables {
    environment  = "test"
    project_name = "test-project"
    vpc_id       = "vpc-12345678"
    region       = "us-east-1"
    alarm_email  = "test@example.com"
  }

  # Verify that the ECS CPU alarm is configured correctly
  assert {
    condition     = aws_cloudwatch_metric_alarm.ecs_cpu.alarm_name == "test-project-test-ecs-cpu-alarm"
    error_message = "ECS CPU alarm name does not match expected value"
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.ecs_cpu.comparison_operator == "GreaterThanThreshold"
    error_message = "ECS CPU alarm comparison operator is not correct"
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.ecs_cpu.metric_name == "CPUUtilization"
    error_message = "ECS CPU alarm metric name is not correct"
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.ecs_cpu.namespace == "AWS/ECS"
    error_message = "ECS CPU alarm namespace is not correct"
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.ecs_cpu.threshold == 80
    error_message = "ECS CPU alarm threshold is not correct"
  }

  assert {
    condition = alltrue([
      length(aws_cloudwatch_metric_alarm.ecs_cpu.alarm_actions) == 1,
      contains([
        for alarm_action in aws_cloudwatch_metric_alarm.ecs_cpu.alarm_actions : alarm_action
      ], aws_sns_topic.alarms.arn)
    ])
    error_message = "ECS CPU alarm is not configured to send notifications to the SNS topic"
  }

  # Verify that the RDS CPU alarm is configured correctly
  assert {
    condition     = aws_cloudwatch_metric_alarm.rds_cpu.alarm_name == "test-project-test-rds-cpu-alarm"
    error_message = "RDS CPU alarm name does not match expected value"
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.rds_cpu.namespace == "AWS/RDS"
    error_message = "RDS CPU alarm namespace is not correct"
  }

  # Verify that the ALB 5XX alarm is configured correctly
  assert {
    condition     = aws_cloudwatch_metric_alarm.alb_5xx.alarm_name == "test-project-test-alb-5xx-alarm"
    error_message = "ALB 5XX alarm name does not match expected value"
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.alb_5xx.metric_name == "HTTPCode_ELB_5XX_Count"
    error_message = "ALB 5XX alarm metric name is not correct"
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.alb_5xx.namespace == "AWS/ApplicationELB"
    error_message = "ALB 5XX alarm namespace is not correct"
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.alb_5xx.statistic == "Sum"
    error_message = "ALB 5XX alarm statistic is not correct"
  }
}

run "cloudwatch_logs" {
  variables {
    environment  = "test"
    project_name = "test-project"
    vpc_id       = "vpc-12345678"
    region       = "us-east-1"
    alarm_email  = "test@example.com"
  }

  # Verify that the CloudWatch log group is created with the correct name
  assert {
    condition     = aws_cloudwatch_log_group.application.name == "/application/test-project-test"
    error_message = "CloudWatch log group name does not match expected value"
  }

  # Verify that the CloudWatch log group has the correct retention period
  assert {
    condition     = aws_cloudwatch_log_group.application.retention_in_days == 30
    error_message = "CloudWatch log group retention period does not match expected value"
  }

  # Verify that the CloudWatch log subscription filter is configured correctly
  assert {
    condition     = aws_cloudwatch_log_subscription_filter.application.name == "test-project-test-application-logs-filter"
    error_message = "CloudWatch log subscription filter name does not match expected value"
  }

  assert {
    condition     = aws_cloudwatch_log_subscription_filter.application.log_group_name == aws_cloudwatch_log_group.application.name
    error_message = "CloudWatch log subscription filter is not associated with the correct log group"
  }

  assert {
    condition     = aws_cloudwatch_log_subscription_filter.application.destination_arn == aws_s3_bucket.logs.arn
    error_message = "CloudWatch log subscription filter destination is not the S3 bucket"
  }

  assert {
    condition     = aws_cloudwatch_log_subscription_filter.application.role_arn == aws_iam_role.logs_export.arn
    error_message = "CloudWatch log subscription filter is not using the logs export IAM role"
  }
}
