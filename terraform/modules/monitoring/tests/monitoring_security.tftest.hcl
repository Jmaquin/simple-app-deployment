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

run "s3_bucket_security" {
  command = apply

  variables {
    environment  = "test"
    project_name = "test-project"
    vpc_id       = "vpc-12345678"
    region       = "us-east-1"
    alarm_email  = "test@example.com"
  }

  # Verify that the S3 bucket has server-side encryption enabled
  assert {
    condition = contains([
      for rule in aws_s3_bucket_server_side_encryption_configuration.logs.rule :
      rule.apply_server_side_encryption_by_default[0].sse_algorithm
    ], "AES256")
    error_message = "S3 bucket server-side encryption is not configured correctly"
  }

  # Verify that the S3 bucket has public access blocked
  assert {
    condition     = aws_s3_bucket_public_access_block.logs.block_public_acls == true
    error_message = "S3 bucket block_public_acls is not enabled"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.logs.block_public_policy == true
    error_message = "S3 bucket block_public_policy is not enabled"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.logs.ignore_public_acls == true
    error_message = "S3 bucket ignore_public_acls is not enabled"
  }

  assert {
    condition     = aws_s3_bucket_public_access_block.logs.restrict_public_buckets == true
    error_message = "S3 bucket restrict_public_buckets is not enabled"
  }

  # Verify that the S3 bucket has a lifecycle policy
  assert {
    condition     = length(aws_s3_bucket_lifecycle_configuration.logs.rule) > 0
    error_message = "S3 bucket does not have a lifecycle policy"
  }

  # Verify that the S3 bucket lifecycle policy includes transitions to lower-cost storage classes
  assert {
    condition     = length(aws_s3_bucket_lifecycle_configuration.logs.rule[0].transition) >= 2
    error_message = "S3 bucket lifecycle policy does not include transitions to lower-cost storage classes"
  }

  # Verify that the S3 bucket lifecycle policy includes expiration
  assert {
    condition     = aws_s3_bucket_lifecycle_configuration.logs.rule[0].expiration[0].days == 365
    error_message = "S3 bucket lifecycle policy does not include expiration after 365 days"
  }
}

run "iam_role_security" {
  variables {
    environment  = "test"
    project_name = "test-project"
    vpc_id       = "vpc-12345678"
    region       = "us-east-1"
    alarm_email  = "test@example.com"
  }

  # Verify that the IAM role for logs export has the correct trust relationship
  assert {
    condition     = can(jsondecode(aws_iam_role.logs_export.assume_role_policy))
    error_message = "IAM role assume_role_policy is not valid JSON"
  }

  assert {
    condition     = jsondecode(aws_iam_role.logs_export.assume_role_policy).Statement[0].Principal.Service == "logs.amazonaws.com"
    error_message = "IAM role trust relationship does not allow logs.amazonaws.com"
  }

  # Verify that the IAM policy for logs export has the correct permissions
  assert {
    condition     = can(jsondecode(aws_iam_policy.logs_export.policy))
    error_message = "IAM policy is not valid JSON"
  }

  assert {
    condition     = contains(jsondecode(aws_iam_policy.logs_export.policy).Statement[0].Action, "s3:PutObject")
    error_message = "IAM policy does not allow s3:PutObject"
  }

  assert {
    condition     = contains(jsondecode(aws_iam_policy.logs_export.policy).Statement[0].Action, "s3:GetBucketAcl")
    error_message = "IAM policy does not allow s3:GetBucketAcl"
  }

  # Verify that the IAM policy has the correct resource scope
  assert {
    condition     = contains(jsondecode(aws_iam_policy.logs_export.policy).Statement[0].Resource, aws_s3_bucket.logs.arn)
    error_message = "IAM policy does not include the S3 bucket ARN in the resource scope"
  }

  assert {
    condition     = contains(jsondecode(aws_iam_policy.logs_export.policy).Statement[0].Resource, "${aws_s3_bucket.logs.arn}/*")
    error_message = "IAM policy does not include the S3 bucket objects in the resource scope"
  }

  # Verify that the IAM role and policy are attached
  assert {
    condition     = aws_iam_role_policy_attachment.logs_export.role == aws_iam_role.logs_export.name
    error_message = "IAM policy is not attached to the logs export role"
  }

  assert {
    condition     = aws_iam_role_policy_attachment.logs_export.policy_arn == aws_iam_policy.logs_export.arn
    error_message = "IAM policy attachment does not reference the correct policy ARN"
  }
}
