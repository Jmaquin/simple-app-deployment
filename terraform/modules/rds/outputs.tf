output "db_instance_id" {
  description = "The ID of the RDS instance"
  value       = var.environment == "prod" ? aws_db_instance.prod[0].id : aws_db_instance.non_prod[0].id
}

output "db_instance_endpoint" {
  description = "The connection endpoint for the RDS instance"
  value       = var.environment == "prod" ? aws_db_instance.prod[0].endpoint : aws_db_instance.non_prod[0].endpoint
}

output "db_instance_address" {
  description = "The hostname of the RDS instance"
  value       = var.environment == "prod" ? aws_db_instance.prod[0].address : aws_db_instance.non_prod[0].address
}

output "db_instance_port" {
  description = "The port of the RDS instance"
  value       = var.environment == "prod" ? aws_db_instance.prod[0].port : aws_db_instance.non_prod[0].port
}

output "db_instance_name" {
  description = "The database name"
  value       = var.environment == "prod" ? aws_db_instance.prod[0].db_name : aws_db_instance.non_prod[0].db_name
}

output "db_subnet_group_id" {
  description = "The ID of the DB subnet group"
  value       = aws_db_subnet_group.main.id
}

output "db_security_group_id" {
  description = "The ID of the security group for the RDS instance"
  value       = aws_security_group.rds.id
}

output "db_kms_key_id" {
  description = "The ARN of the KMS key used for RDS encryption"
  value       = aws_kms_key.rds.arn
}

output "db_secret_arn" {
  description = "The ARN of the Secrets Manager secret containing RDS credentials"
  value       = aws_secretsmanager_secret.rds.arn
}

output "db_parameter_group_id" {
  description = "The ID of the DB parameter group"
  value       = aws_db_parameter_group.main.id
}

output "db_monitoring_role_arn" {
  description = "The ARN of the IAM role used for RDS enhanced monitoring"
  value       = aws_iam_role.rds_monitoring.arn
}
