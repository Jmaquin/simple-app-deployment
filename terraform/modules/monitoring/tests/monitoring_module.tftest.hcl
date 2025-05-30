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

run "create_monitoring_resources" {
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

  # Verify that the SNS topic is created with the correct name
  assert {
    condition     = aws_sns_topic.alarms.name == "test-project-test-alarms"
    error_message = "SNS topic name does not match expected value"
  }

  # Verify that the SNS subscription is created with the correct email
  assert {
    condition     = aws_sns_topic_subscription.email.endpoint == "test@example.com"
    error_message = "SNS subscription email does not match expected value"
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

  # Verify that the S3 bucket is created with the correct name
  assert {
    condition     = aws_s3_bucket.logs.bucket == "test-project-test-logs"
    error_message = "S3 bucket name does not match expected value"
  }

  # Verify that the S3 bucket has public access blocked
  assert {
    condition = alltrue([
      aws_s3_bucket_public_access_block.logs.block_public_acls == true,
      aws_s3_bucket_public_access_block.logs.block_public_policy == true,
      aws_s3_bucket_public_access_block.logs.ignore_public_acls == true,
      aws_s3_bucket_public_access_block.logs.restrict_public_buckets == true
    ])
    error_message = "S3 bucket public access block is not configured correctly"
  }

  # Verify that the IAM role for logs export is created with the correct name
  assert {
    condition     = aws_iam_role.logs_export.name == "test-project-test-logs-export-role"
    error_message = "IAM role name does not match expected value"
  }

  # Verify that the IAM policy for logs export is created with the correct name
  assert {
    condition     = aws_iam_policy.logs_export.name == "test-project-test-logs-export-policy"
    error_message = "IAM policy name does not match expected value"
  }

  # Verify outputs
  assert {
    condition     = output.dashboard_name == "test-project-test-dashboard"
    error_message = "dashboard_name output does not match expected value"
  }

  assert {
    condition     = output.alarm_topic_arn == aws_sns_topic.alarms.arn
    error_message = "alarm_topic_arn output does not match expected value"
  }

  assert {
    condition     = output.log_group_name == "/application/test-project-test"
    error_message = "log_group_name output does not match expected value"
  }

  assert {
    condition     = output.logs_bucket_name == "test-project-test-logs"
    error_message = "logs_bucket_name output does not match expected value"
  }
}
