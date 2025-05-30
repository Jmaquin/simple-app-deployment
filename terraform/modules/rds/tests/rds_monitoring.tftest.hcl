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

run "parameter_group_configuration" {
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

  # Verify that the parameter group is created with the correct name
  assert {
    condition     = aws_db_parameter_group.main.name == "test-project-test-pg-params"
    error_message = "Parameter group name does not match expected value"
  }

  assert {
    condition     = aws_db_parameter_group.main.family == "postgres17"
    error_message = "Parameter group family does not match expected value"
  }

  assert {
    condition     = aws_db_parameter_group.main.description == "Parameter group for test-project test PostgreSQL instance"
    error_message = "Parameter group description does not match expected value"
  }

  # Verify that the parameter group has the correct parameters
  assert {
    condition = alltrue([
      contains([for param in aws_db_parameter_group.main.parameter : param.name], "log_connections"),
      contains([
        for param in aws_db_parameter_group.main.parameter : param.value
        if param.name == "log_connections"
      ], "1")
    ])
    error_message = "Parameter group does not have log_connections=1"
  }

  assert {
    condition = alltrue([
      contains([for param in aws_db_parameter_group.main.parameter : param.name], "log_disconnections"),
      contains([
        for param in aws_db_parameter_group.main.parameter : param.value
        if param.name == "log_disconnections"
      ], "1")
    ])
    error_message = "Parameter group does not have log_disconnections=1"
  }

  assert {
    condition = alltrue([
      contains([for param in aws_db_parameter_group.main.parameter : param.name], "log_statement"),
      contains([
        for param in aws_db_parameter_group.main.parameter : param.value
        if param.name == "log_statement"
      ], "ddl")
    ])
    error_message = "Parameter group does not have log_statement=ddl"
  }

  assert {
    condition = alltrue([
      contains([for param in aws_db_parameter_group.main.parameter : param.name], "log_min_duration_statement"),
      contains([
        for param in aws_db_parameter_group.main.parameter : param.value
        if param.name == "log_min_duration_statement"
      ], "1000")
    ])
    error_message = "Parameter group does not have log_min_duration_statement=1000"
  }

  # Verify that the RDS instance uses the parameter group
  assert {
    condition     = aws_db_instance.non_prod[0].parameter_group_name == aws_db_parameter_group.main.name
    error_message = "RDS instance is not using the parameter group"
  }
}

run "monitoring_configuration" {
  variables {
    environment        = "test"
    project_name       = "test-project"
    vpc_id             = "vpc-12345678"
    private_subnet_ids = ["subnet-12345678", "subnet-87654321"]
    db_name            = "testdb"
    db_username        = "testuser"
    db_password        = "testpassword"
  }

  # Verify that the monitoring role is created with the correct name
  assert {
    condition     = aws_iam_role.rds_monitoring.name == "test-project-test-rds-monitoring-role"
    error_message = "Monitoring role name does not match expected value"
  }

  # Verify that the monitoring role has the correct trust relationship
  assert {
    condition     = can(jsondecode(aws_iam_role.rds_monitoring.assume_role_policy))
    error_message = "Monitoring role assume_role_policy is not valid JSON"
  }

  assert {
    condition     = jsondecode(aws_iam_role.rds_monitoring.assume_role_policy).Statement[0].Principal.Service == "monitoring.rds.amazonaws.com"
    error_message = "Monitoring role trust relationship does not allow monitoring.rds.amazonaws.com"
  }

  # Verify that the monitoring role has the correct policy attached
  assert {
    condition     = aws_iam_role_policy_attachment.rds_monitoring.role == aws_iam_role.rds_monitoring.name
    error_message = "Monitoring role policy attachment is not associated with the monitoring role"
  }

  assert {
    condition     = aws_iam_role_policy_attachment.rds_monitoring.policy_arn == "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
    error_message = "Monitoring role does not have the AmazonRDSEnhancedMonitoringRole policy attached"
  }

  # Verify that the RDS instance has monitoring enabled
  assert {
    condition     = aws_db_instance.non_prod[0].monitoring_interval == 60
    error_message = "RDS monitoring interval should be 60 seconds"
  }

  assert {
    condition     = aws_db_instance.non_prod[0].monitoring_role_arn == aws_iam_role.rds_monitoring.arn
    error_message = "RDS instance is not using the monitoring role"
  }

  # Verify that the RDS instance has CloudWatch logs exports enabled
  assert {
    condition     = contains(aws_db_instance.non_prod[0].enabled_cloudwatch_logs_exports, "postgresql")
    error_message = "RDS instance does not export postgresql logs to CloudWatch"
  }

  assert {
    condition     = contains(aws_db_instance.non_prod[0].enabled_cloudwatch_logs_exports, "upgrade")
    error_message = "RDS instance does not export upgrade logs to CloudWatch"
  }

  # Verify that the RDS instance has Performance Insights enabled
  assert {
    condition     = aws_db_instance.non_prod[0].performance_insights_enabled == true
    error_message = "RDS Performance Insights is not enabled"
  }

  assert {
    condition     = aws_db_instance.non_prod[0].performance_insights_retention_period == 7
    error_message = "RDS Performance Insights retention period should be 7 days"
  }
}
