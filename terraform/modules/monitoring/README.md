# AWS Monitoring Terraform Module

This Terraform module creates a comprehensive AWS monitoring setup with CloudWatch dashboards, alarms, log groups, SNS notifications, and S3 log storage.

## Features

- CloudWatch dashboard with widgets for ECS, RDS, and ALB metrics
- CloudWatch metric alarms for ECS CPU and memory utilization
- CloudWatch metric alarms for RDS CPU utilization and storage space
- CloudWatch metric alarms for ALB 5XX errors
- SNS topic and email subscription for alarm notifications
- CloudWatch log group for application logs
- S3 bucket for log storage with lifecycle policies
- IAM roles and policies for log export

## Usage

```hcl
module "monitoring" {
  source = "./modules/monitoring"

  environment  = "dev"
  project_name = "my-project"
  vpc_id       = module.vpc.vpc_id
  region       = "us-east-1"
  alarm_email  = "alerts@example.com"
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
| region | AWS region | `string` | `"us-east-1"` | no |
| alarm_email | Email address to send alarms to | `string` | n/a | yes |
| log_retention_days | Number of days to retain logs in CloudWatch | `number` | `30` | no |
| alarm_cpu_threshold | Threshold for CPU utilization alarm | `number` | `80` | no |
| alarm_memory_threshold | Threshold for memory utilization alarm | `number` | `80` | no |
| alarm_storage_threshold | Threshold for storage space alarm (in bytes) | `number` | `5000000000` | no |
| alarm_5xx_threshold | Threshold for 5XX error count alarm | `number` | `10` | no |
| dashboard_period | Period for dashboard metrics (in seconds) | `number` | `300` | no |
| enable_s3_log_export | Whether to enable exporting logs to S3 | `bool` | `true` | no |
| log_lifecycle_transition_standard_ia_days | Number of days before transitioning logs to STANDARD_IA storage | `number` | `30` | no |
| log_lifecycle_transition_glacier_days | Number of days before transitioning logs to GLACIER storage | `number` | `90` | no |
| log_lifecycle_expiration_days | Number of days before expiring logs | `number` | `365` | no |

## Outputs

| Name | Description |
|------|-------------|
| dashboard_name | The name of the CloudWatch dashboard |
| alarm_topic_arn | The ARN of the SNS topic for alarms |
| log_group_name | The name of the CloudWatch log group for application logs |
| log_group_arn | The ARN of the CloudWatch log group for application logs |
| logs_bucket_name | The name of the S3 bucket for logs |
| logs_bucket_arn | The ARN of the S3 bucket for logs |
| logs_export_role_arn | The ARN of the IAM role for CloudWatch Logs to S3 export |
| ecs_cpu_alarm_arn | The ARN of the ECS CPU utilization alarm |
| ecs_memory_alarm_arn | The ARN of the ECS memory utilization alarm |
| rds_cpu_alarm_arn | The ARN of the RDS CPU utilization alarm |
| rds_storage_alarm_arn | The ARN of the RDS free storage space alarm |
| alb_5xx_alarm_arn | The ARN of the ALB 5XX error count alarm |

## CloudWatch Dashboard

The module creates a CloudWatch dashboard with the following widgets:

1. ECS CPU Utilization
2. ECS Memory Utilization
3. ALB Request Count
4. ALB Response Time
5. RDS CPU Utilization
6. RDS Free Storage Space

The dashboard provides a comprehensive view of the application's performance and resource utilization.

## CloudWatch Alarms

The module configures several CloudWatch metric alarms:

1. ECS CPU Utilization Alarm:
   - Triggers when CPU utilization exceeds 80% for 2 evaluation periods
   - Sends notifications to the configured email address

2. ECS Memory Utilization Alarm:
   - Triggers when memory utilization exceeds 80% for 2 evaluation periods
   - Sends notifications to the configured email address

3. RDS CPU Utilization Alarm:
   - Triggers when CPU utilization exceeds 80% for 2 evaluation periods
   - Sends notifications to the configured email address

4. RDS Free Storage Space Alarm:
   - Triggers when free storage space falls below 5GB for 2 evaluation periods
   - Sends notifications to the configured email address

5. ALB 5XX Error Count Alarm:
   - Triggers when the number of 5XX errors exceeds 10 for 2 evaluation periods
   - Sends notifications to the configured email address

## SNS Notifications

The module sets up an SNS topic and email subscription for alarm notifications:

1. SNS Topic:
   - Named according to project and environment
   - Used as the target for all CloudWatch alarms

2. Email Subscription:
   - Subscribes the provided email address to the SNS topic
   - Receives notifications when alarms are triggered

## Log Management

The module configures comprehensive log management:

1. CloudWatch Log Group:
   - Named according to project and environment
   - Configurable retention period (default: 30 days)

2. S3 Bucket for Log Storage:
   - Named according to project and environment
   - Server-side encryption with AES256
   - Public access blocked
   - Lifecycle policies for cost-effective storage:
     - Transition to STANDARD_IA after 30 days
     - Transition to GLACIER after 90 days
     - Expiration after 365 days

3. Log Export:
   - CloudWatch Logs subscription filter to export logs to S3
   - IAM role with appropriate permissions for log export

## Security Features

The module implements several security features:

1. S3 Bucket Security:
   - Server-side encryption enabled
   - Public access blocked
   - Secure lifecycle management

2. IAM Roles:
   - Least privilege permissions for log export
   - Limited to required actions on specific resources

## Testing

This module includes tests using Terraform's built-in testing framework. The tests verify:

- Basic monitoring resource creation and configuration
- Security configurations
- CloudWatch alarm and dashboard setup

To run the tests, navigate to the module directory and run:

```bash
terraform test
```
