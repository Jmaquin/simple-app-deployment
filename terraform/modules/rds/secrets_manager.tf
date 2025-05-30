resource "aws_secretsmanager_secret" "rds" {
  name        = "${var.project_name}/${var.environment}/rds"
  description = "RDS credentials for ${var.project_name} ${var.environment}"
  kms_key_id  = aws_kms_key.rds.arn
}

resource "aws_secretsmanager_secret_version" "prod_rds" {
  count     = var.environment == "prod" ? 1 : 0
  secret_id = aws_secretsmanager_secret.rds.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password == "" ? random_password.rds[0].result : var.db_password
    engine   = "postgres"
    host     = aws_db_instance.prod[0].address
    port     = 5432
    dbname   = var.db_name
  })
}

resource "aws_secretsmanager_secret_version" "non_prod_rds" {
  count     = var.environment != "prod" ? 1 : 0
  secret_id = aws_secretsmanager_secret.rds.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password == "" ? random_password.rds[0].result : var.db_password
    engine   = "postgres"
    host     = aws_db_instance.non_prod[0].address
    port     = 5432
    dbname   = var.db_name
  })
}
