mock_provider "aws" {
  mock_resource "aws_kms_key" {
    defaults = {
      arn = "arn:aws:kms:eu-west-3:123456789012:key/key-id"
    }
  }

  mock_resource "aws_iam_role" {
    defaults = {
      arn = "arn:aws:iam::123456789012:role/test-role"
    }
  }

  mock_data "aws_vpc" {
    defaults = {
      cidr_block = "10.0.0.0/16"
    }
  }
}

run "security_group_configuration" {
  command = apply

  variables {
    environment        = "test"
    project_name       = "test-project"
    vpc_id             = "vpc-12345678"
    private_subnet_ids = ["subnet-12345678", "subnet-87654321"]
    db_name            = "testdb"
    db_username        = "testuser"
    db_password        = "testpassword"
  }

  # Verify that the security group is created with the correct name
  assert {
    condition     = aws_security_group.rds.name == "test-project-test-rds-sg"
    error_message = "Security group name does not match expected value"
  }

  assert {
    condition     = aws_security_group.rds.description == "Security group for RDS PostgreSQL instance"
    error_message = "Security group description does not match expected value"
  }

  assert {
    condition     = aws_security_group.rds.vpc_id == var.vpc_id
    error_message = "Security group is not associated with the correct VPC"
  }

  # Verify that the security group has the correct ingress rule
  assert {
    condition = alltrue([
      length(aws_security_group.rds.ingress) == 1,
      contains([for rule in aws_security_group.rds.ingress : rule.from_port], 5432),
      contains([for rule in aws_security_group.rds.ingress : rule.to_port], 5432),
      contains([for rule in aws_security_group.rds.ingress : rule.protocol], "tcp"),
      contains([
        for rule in aws_security_group.rds.ingress : rule.description
      ], "Allow PostgreSQL traffic from within VPC")
    ])
    error_message = "Security group ingress rule is not correctly configured"
  }

  # Verify that the security group has the correct egress rules
  assert {
    condition = alltrue([
      length(aws_security_group.rds.egress) == 2,
      contains([for rule in aws_security_group.rds.egress : rule.from_port], 53),
      contains([for rule in aws_security_group.rds.egress : rule.to_port], 53),
      contains([for rule in aws_security_group.rds.egress : rule.protocol], "udp"),
      contains([for rule in aws_security_group.rds.egress : rule.from_port], 5432),
      contains([for rule in aws_security_group.rds.egress : rule.to_port], 5432),
      contains([for rule in aws_security_group.rds.egress : rule.protocol], "tcp"),
      contains([
        for rule in aws_security_group.rds.egress : rule.description
      ], "Allow DNS lookups within VPC"),
      contains([
        for rule in aws_security_group.rds.egress : rule.description
      ], "Allow PostgreSQL connections within VPC for replication")
    ])
    error_message = "Security group egress rule is not correctly configured"
  }

  # Verify that the RDS instance uses the security group
  assert {
    condition     = contains(aws_db_instance.non_prod[0].vpc_security_group_ids, aws_security_group.rds.id)
    error_message = "RDS instance is not using the security group"
  }
}

run "encryption_configuration" {
  variables {
    environment        = "test"
    project_name       = "test-project"
    vpc_id             = "vpc-12345678"
    private_subnet_ids = ["subnet-12345678", "subnet-87654321"]
    db_name            = "testdb"
    db_username        = "testuser"
    db_password        = "testpassword"
  }

  # Verify that the KMS key is created with the correct configuration
  assert {
    condition     = aws_kms_key.rds.description == "KMS key for RDS encryption for test-project test"
    error_message = "KMS key description does not match expected value"
  }

  assert {
    condition     = aws_kms_key.rds.deletion_window_in_days == 10
    error_message = "KMS key deletion window does not match expected value"
  }

  assert {
    condition     = aws_kms_key.rds.enable_key_rotation == true
    error_message = "KMS key rotation is not enabled"
  }

  # Verify that the KMS alias is created with the correct name
  assert {
    condition     = aws_kms_alias.rds.name == "alias/test-project-test-rds-kms-key"
    error_message = "KMS alias name does not match expected value"
  }

  assert {
    condition     = aws_kms_alias.rds.target_key_id == aws_kms_key.rds.key_id
    error_message = "KMS alias is not associated with the correct KMS key"
  }

  # Verify that the RDS instance uses the KMS key for encryption
  assert {
    condition     = aws_db_instance.non_prod[0].storage_encrypted == true
    error_message = "RDS storage encryption is not enabled"
  }

  assert {
    condition     = aws_db_instance.non_prod[0].kms_key_id == aws_kms_key.rds.arn
    error_message = "RDS instance is not using the KMS key for encryption"
  }

  # Verify that Performance Insights is encrypted with the KMS key
  assert {
    condition     = aws_db_instance.non_prod[0].performance_insights_enabled == true
    error_message = "RDS Performance Insights is not enabled"
  }

  assert {
    condition     = aws_db_instance.non_prod[0].performance_insights_kms_key_id == aws_kms_key.rds.arn
    error_message = "RDS Performance Insights is not using the KMS key for encryption"
  }
}

run "secrets_manager_integration" {
  variables {
    environment        = "test"
    project_name       = "test-project"
    vpc_id             = "vpc-12345678"
    private_subnet_ids = ["subnet-12345678", "subnet-87654321"]
    db_name            = "testdb"
    db_username        = "testuser"
    db_password        = "testpassword"
  }

  # Verify that the Secrets Manager secret is created with the correct name
  assert {
    condition     = aws_secretsmanager_secret.rds.name == "test-project/test/rds"
    error_message = "Secrets Manager secret name does not match expected value"
  }

  assert {
    condition     = aws_secretsmanager_secret.rds.description == "RDS credentials for test-project test"
    error_message = "Secrets Manager secret description does not match expected value"
  }

  # Verify that the Secrets Manager secret is encrypted with the KMS key
  assert {
    condition     = aws_secretsmanager_secret.rds.kms_key_id == aws_kms_key.rds.arn
    error_message = "Secrets Manager secret is not encrypted with the KMS key"
  }

  # Verify that the Secrets Manager secret version contains the correct data
  assert {
    condition     = can(jsondecode(aws_secretsmanager_secret_version.non_prod_rds[0].secret_string))
    error_message = "Secrets Manager secret version does not contain valid JSON"
  }

  assert {
    condition = alltrue([
      jsondecode(aws_secretsmanager_secret_version.non_prod_rds[0].secret_string).username == var.db_username,
      jsondecode(aws_secretsmanager_secret_version.non_prod_rds[0].secret_string).password == var.db_password,
      jsondecode(aws_secretsmanager_secret_version.non_prod_rds[0].secret_string).engine == "postgres",
      jsondecode(aws_secretsmanager_secret_version.non_prod_rds[0].secret_string).host == aws_db_instance.non_prod[0].address,
      jsondecode(aws_secretsmanager_secret_version.non_prod_rds[0].secret_string).port == 5432,
      jsondecode(aws_secretsmanager_secret_version.non_prod_rds[0].secret_string).dbname == var.db_name
    ])
    error_message = "Secrets Manager secret version does not contain the correct data"
  }
}

run "random_password_generation" {
  variables {
    environment        = "test"
    project_name       = "test-project"
    vpc_id             = "vpc-12345678"
    private_subnet_ids = ["subnet-12345678", "subnet-87654321"]
    db_name            = "testdb"
    db_username        = "testuser"
    db_password        = "" # Empty password to trigger random password generation
  }

  # Verify that a random password is generated when db_password is empty
  assert {
    condition     = length(random_password.rds) == 1
    error_message = "Random password resource should be created when db_password is empty"
  }

  assert {
    condition     = random_password.rds[0].length == 16
    error_message = "Random password length should be 16"
  }

  assert {
    condition     = random_password.rds[0].special == false
    error_message = "Random password should not include special characters"
  }

  # Verify that the RDS instance uses the random password
  assert {
    condition     = aws_db_instance.non_prod[0].password == random_password.rds[0].result
    error_message = "RDS instance is not using the random password"
  }

  # Verify that the Secrets Manager secret version contains the random password
  assert {
    condition     = jsondecode(aws_secretsmanager_secret_version.non_prod_rds[0].secret_string).password == random_password.rds[0].result
    error_message = "Secrets Manager secret version does not contain the random password"
  }
}
