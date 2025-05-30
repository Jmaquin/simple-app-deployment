# AWS RDS Terraform Module

This Terraform module creates a complete AWS RDS PostgreSQL database setup with security groups, encryption, monitoring, and Secrets Manager integration.

## Features

- PostgreSQL RDS instance with configurable settings
- Different configurations for production and non-production environments
- Security group with restricted access from within the VPC
- KMS encryption for database storage and credentials
- DB parameter group with logging configurations
- Enhanced monitoring with CloudWatch integration
- Performance Insights enabled with KMS encryption
- CloudWatch Logs exports for PostgreSQL and upgrade logs
- Secrets Manager integration for secure credential management
- Random password generation (optional)

## Usage

```hcl
module "rds" {
  source = "./modules/rds"

  environment        = "dev"
  project_name       = "my-project"
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  db_name            = "mydb"
  db_username        = "dbadmin"
}
```

## Requirements

| Name | Version  |
|------|----------|
| terraform | >= 1.6.0 |
| aws | >= 5.0.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment name (e.g., dev, staging, prod) | `string` | n/a | yes |
| project_name | Name of the project | `string` | n/a | yes |
| vpc_id | ID of the VPC | `string` | n/a | yes |
| private_subnet_ids | List of private subnet IDs | `list(string)` | n/a | yes |
| db_name | Name of the database | `string` | n/a | yes |
| db_username | Username for the database | `string` | n/a | yes |
| db_password | Password for the database | `string` | `""` | no |
| db_instance_class | Instance class for the RDS instance | `string` | `"db.t3.medium"` | no |
| db_major_engine_version | Major engine version for PostgreSQL | `string` | `"17"` | no |
| db_engine_version | Engine version for PostgreSQL | `string` | `"17.5"` | no |
| db_allocated_storage | Allocated storage for the RDS instance (in GB) | `number` | `20` | no |
| db_max_allocated_storage | Maximum allocated storage for the RDS instance (in GB) | `number` | `100` | no |
| db_backup_retention_period | Backup retention period in days | `number` | `7` | no |
| db_backup_window | Preferred backup window | `string` | `"03:00-04:00"` | no |
| db_maintenance_window | Preferred maintenance window | `string` | `"sun:04:00-sun:05:00"` | no |
| db_multi_az | Whether to enable Multi-AZ deployment | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| db_instance_id | The ID of the RDS instance |
| db_instance_endpoint | The connection endpoint for the RDS instance |
| db_instance_address | The hostname of the RDS instance |
| db_instance_port | The port of the RDS instance |
| db_instance_name | The database name |
| db_subnet_group_id | The ID of the DB subnet group |
| db_security_group_id | The ID of the security group for the RDS instance |
| db_kms_key_id | The ARN of the KMS key used for RDS encryption |
| db_secret_arn | The ARN of the Secrets Manager secret containing RDS credentials |
| db_parameter_group_id | The ID of the DB parameter group |
| db_monitoring_role_arn | The ARN of the IAM role used for RDS enhanced monitoring |

## Database Configuration

The module creates an RDS PostgreSQL instance with the following configuration:

1. Storage: GP3 storage type with encryption using a dedicated KMS key
2. Networking: Placed in private subnets with a security group that allows access only from within the VPC
3. Credentials: Username and password stored in AWS Secrets Manager
4. Logging: Parameter group configured to log connections, disconnections, DDL statements, and slow queries

## Environment-Specific Settings

The module applies different settings based on the environment:

### Production Environment
- Deletion protection enabled
- Final snapshot required
- Changes applied during maintenance window
- Lifecycle policy to prevent accidental destruction

### Non-Production Environments
- Deletion protection disabled
- No final snapshot required
- Changes applied immediately
- No lifecycle policy to prevent destruction

## Security Features

The module implements several security features:

1. Network security:
   - RDS instance placed in private subnets
   - Security group allows PostgreSQL traffic only from within the VPC
   - No public access allowed

2. Encryption:
   - Storage encryption using a dedicated KMS key
   - Performance Insights encryption using the same KMS key
   - Automatic key rotation enabled

3. Credential management:
   - Credentials stored in AWS Secrets Manager
   - Secret encrypted with the same KMS key
   - Optional random password generation

## Monitoring and Logging

The module configures comprehensive monitoring and logging:

1. Enhanced Monitoring:
   - 60-second monitoring interval
   - Dedicated IAM role with appropriate permissions

2. CloudWatch Logs:
   - PostgreSQL logs exported to CloudWatch
   - Upgrade logs exported to CloudWatch

3. Performance Insights:
   - Enabled with 7-day retention period
   - Encrypted with the same KMS key as the database

4. Parameter Group:
   - Configured to log connections and disconnections
   - Configured to log DDL statements
   - Configured to log queries that take longer than 1 second

## Testing

This module includes comprehensive tests using Terraform's built-in testing framework. The tests verify:

- Basic RDS instance creation and configuration
- Security group and encryption setup
- Monitoring and logging configuration
- Secrets Manager integration

To run the tests, navigate to the module directory and run:

```bash
terraform test
```
