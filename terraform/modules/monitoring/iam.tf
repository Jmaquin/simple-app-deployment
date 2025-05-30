resource "aws_iam_role" "logs_export" {
  name = "${var.project_name}-${var.environment}-logs-export-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "logs.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-logs-export-role"
  }
}

resource "aws_iam_policy" "logs_export" {
  name        = "${var.project_name}-${var.environment}-logs-export-policy"
  description = "Policy for CloudWatch Logs to S3 Export"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:PutObject",
          "s3:GetBucketAcl"
        ]
        Effect = "Allow"
        Resource = [
          aws_s3_bucket.logs.arn,
          "${aws_s3_bucket.logs.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "logs_export" {
  role       = aws_iam_role.logs_export.name
  policy_arn = aws_iam_policy.logs_export.arn
}
