resource "aws_security_group" "rds" {
  name        = "${var.project_name}-${var.environment}-rds-sg"
  description = "Security group for RDS PostgreSQL instance"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.selected.cidr_block]
    description = "Allow PostgreSQL traffic from within VPC"
  }

  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = [data.aws_vpc.selected.cidr_block]
    description = "Allow DNS lookups within VPC"
  }

  egress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.selected.cidr_block]
    description = "Allow PostgreSQL connections within VPC for replication"
  }
}

resource "aws_db_subnet_group" "main" {
  name        = "${var.project_name}-${var.environment}-db-subnet-group"
  description = "DB subnet group for ${var.project_name} ${var.environment}"
  subnet_ids  = var.private_subnet_ids
}

resource "random_password" "rds" {
  count   = var.db_password == "" ? 1 : 0
  length  = 16
  special = false
}

resource "aws_db_instance" "prod" {
  count                                 = var.environment == "prod" ? 1 : 0
  identifier                            = "${var.project_name}-${var.environment}-db"
  engine                                = "postgres"
  engine_version                        = var.db_engine_version
  instance_class                        = var.db_instance_class
  allocated_storage                     = var.db_allocated_storage
  max_allocated_storage                 = var.db_max_allocated_storage
  storage_type                          = "gp3"
  storage_encrypted                     = true
  kms_key_id                            = aws_kms_key.rds.arn
  db_name                               = var.db_name
  username                              = var.db_username
  password                              = var.db_password == "" ? random_password.rds[0].result : var.db_password
  port                                  = 5432
  vpc_security_group_ids                = [aws_security_group.rds.id]
  db_subnet_group_name                  = aws_db_subnet_group.main.name
  parameter_group_name                  = aws_db_parameter_group.main.name
  backup_retention_period               = var.db_backup_retention_period
  backup_window                         = var.db_backup_window
  maintenance_window                    = var.db_maintenance_window
  multi_az                              = var.db_multi_az
  publicly_accessible                   = false
  skip_final_snapshot                   = false
  final_snapshot_identifier             = "${var.project_name}-${var.environment}-db-final-snapshot"
  deletion_protection                   = true
  copy_tags_to_snapshot                 = true
  apply_immediately                     = false
  auto_minor_version_upgrade            = true
  performance_insights_enabled          = true
  performance_insights_kms_key_id       = aws_kms_key.rds.arn
  performance_insights_retention_period = 7
  enabled_cloudwatch_logs_exports       = ["postgresql", "upgrade"]
  monitoring_interval                   = 60
  monitoring_role_arn                   = aws_iam_role.rds_monitoring.arn

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_db_instance" "non_prod" {
  count                                 = var.environment != "prod" ? 1 : 0
  identifier                            = "${var.project_name}-${var.environment}-db"
  engine                                = "postgres"
  engine_version                        = var.db_engine_version
  instance_class                        = var.db_instance_class
  allocated_storage                     = var.db_allocated_storage
  max_allocated_storage                 = var.db_max_allocated_storage
  storage_type                          = "gp3"
  storage_encrypted                     = true
  kms_key_id                            = aws_kms_key.rds.arn
  db_name                               = var.db_name
  username                              = var.db_username
  password                              = var.db_password == "" ? random_password.rds[0].result : var.db_password
  port                                  = 5432
  vpc_security_group_ids                = [aws_security_group.rds.id]
  db_subnet_group_name                  = aws_db_subnet_group.main.name
  parameter_group_name                  = aws_db_parameter_group.main.name
  backup_retention_period               = var.db_backup_retention_period
  backup_window                         = var.db_backup_window
  maintenance_window                    = var.db_maintenance_window
  multi_az                              = var.db_multi_az
  publicly_accessible                   = false
  skip_final_snapshot                   = true
  final_snapshot_identifier             = null
  deletion_protection                   = false
  copy_tags_to_snapshot                 = true
  apply_immediately                     = true
  auto_minor_version_upgrade            = true
  performance_insights_enabled          = true
  performance_insights_kms_key_id       = aws_kms_key.rds.arn
  performance_insights_retention_period = 7
  enabled_cloudwatch_logs_exports       = ["postgresql", "upgrade"]
  monitoring_interval                   = 60
  monitoring_role_arn                   = aws_iam_role.rds_monitoring.arn
}

resource "aws_db_parameter_group" "main" {
  name        = "${var.project_name}-${var.environment}-pg-params"
  family      = "postgres${var.db_major_engine_version}"
  description = "Parameter group for ${var.project_name} ${var.environment} PostgreSQL instance"

  parameter {
    name  = "log_connections"
    value = "1"
  }

  parameter {
    name  = "log_disconnections"
    value = "1"
  }

  parameter {
    name  = "log_statement"
    value = "ddl"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "1000"
  }
}
