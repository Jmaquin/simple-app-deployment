mock_provider "aws" {
  mock_resource "aws_kms_key" {
    defaults = {
      arn = "arn:aws:kms:eu-west-3:123456789012:key/key-id"
    }
  }

  mock_resource "aws_iam_role" {
    defaults = {
      arn = "arn:aws:iam::123456789012:role/role-name"
    }
  }

  mock_data "aws_vpc" {
    defaults = {
      cidr_block = "10.0.0.0/16"
    }
  }
}

run "create_rds_instance" {
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

  # Verify that the RDS instance is created with the correct configuration
  assert {
    condition     = aws_db_instance.non_prod[0].identifier == "test-project-test-db"
    error_message = "RDS instance identifier does not match expected value"
  }

  assert {
    condition     = aws_db_instance.non_prod[0].engine == "postgres"
    error_message = "RDS engine is not postgres"
  }

  assert {
    condition     = aws_db_instance.non_prod[0].engine_version == "17.5"
    error_message = "RDS engine version does not match expected value"
  }

  assert {
    condition     = aws_db_instance.non_prod[0].instance_class == "db.t3.medium"
    error_message = "RDS instance class does not match expected value"
  }

  assert {
    condition     = aws_db_instance.non_prod[0].allocated_storage == 20
    error_message = "RDS allocated storage does not match expected value"
  }

  assert {
    condition     = aws_db_instance.non_prod[0].max_allocated_storage == 100
    error_message = "RDS max allocated storage does not match expected value"
  }

  assert {
    condition     = aws_db_instance.non_prod[0].storage_type == "gp3"
    error_message = "RDS storage type is not gp3"
  }

  assert {
    condition     = aws_db_instance.non_prod[0].storage_encrypted == true
    error_message = "RDS storage encryption is not enabled"
  }

  assert {
    condition     = aws_db_instance.non_prod[0].db_name == "testdb"
    error_message = "RDS database name does not match expected value"
  }

  assert {
    condition     = aws_db_instance.non_prod[0].username == "testuser"
    error_message = "RDS username does not match expected value"
  }

  assert {
    condition     = aws_db_instance.non_prod[0].password == "testpassword"
    error_message = "RDS password does not match expected value"
  }

  assert {
    condition     = aws_db_instance.non_prod[0].port == 5432
    error_message = "RDS port is not 5432"
  }

  assert {
    condition     = aws_db_instance.non_prod[0].multi_az == true
    error_message = "RDS multi-AZ is not enabled"
  }

  assert {
    condition     = aws_db_instance.non_prod[0].publicly_accessible == false
    error_message = "RDS instance should not be publicly accessible"
  }

  # Verify that the DB subnet group is created correctly
  assert {
    condition     = aws_db_subnet_group.main.name == "test-project-test-db-subnet-group"
    error_message = "DB subnet group name does not match expected value"
  }

  assert {
    condition     = length(aws_db_subnet_group.main.subnet_ids) == 2
    error_message = "DB subnet group should have 2 subnets"
  }

  # Verify outputs
  assert {
    condition     = output.db_instance_id == aws_db_instance.non_prod[0].id
    error_message = "db_instance_id output does not match expected value"
  }

  assert {
    condition     = output.db_instance_endpoint == aws_db_instance.non_prod[0].endpoint
    error_message = "db_instance_endpoint output does not match expected value"
  }

  assert {
    condition     = output.db_instance_address == aws_db_instance.non_prod[0].address
    error_message = "db_instance_address output does not match expected value"
  }

  assert {
    condition     = output.db_instance_name == aws_db_instance.non_prod[0].db_name
    error_message = "db_instance_name output does not match expected value"
  }
}

run "custom_instance_config" {
  variables {
    environment              = "test"
    project_name             = "test-project"
    vpc_id                   = "vpc-12345678"
    private_subnet_ids       = ["subnet-12345678", "subnet-87654321"]
    db_name                  = "testdb"
    db_username              = "testuser"
    db_password              = "testpassword"
    db_instance_class        = "db.t3.small"
    db_allocated_storage     = 50
    db_max_allocated_storage = 200
    db_multi_az              = false
  }

  assert {
    condition     = aws_db_instance.non_prod[0].instance_class == "db.t3.small"
    error_message = "RDS instance class does not match custom value"
  }

  assert {
    condition     = aws_db_instance.non_prod[0].allocated_storage == 50
    error_message = "RDS allocated storage does not match custom value"
  }

  assert {
    condition     = aws_db_instance.non_prod[0].max_allocated_storage == 200
    error_message = "RDS max allocated storage does not match custom value"
  }

  assert {
    condition     = aws_db_instance.non_prod[0].multi_az == false
    error_message = "RDS multi-AZ should be disabled"
  }
}
