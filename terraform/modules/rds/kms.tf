resource "aws_kms_key" "rds" {
  description             = "KMS key for RDS encryption for ${var.project_name} ${var.environment}"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}

resource "aws_kms_alias" "rds" {
  name          = "alias/${var.project_name}-${var.environment}-rds-kms-key"
  target_key_id = aws_kms_key.rds.key_id
}
