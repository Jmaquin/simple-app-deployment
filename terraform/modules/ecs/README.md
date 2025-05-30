# AWS ECS Terraform Module

This Terraform module creates a complete AWS ECS Fargate service with an Application Load Balancer, auto-scaling, monitoring, and security configurations.

## Features

- ECS Fargate cluster with Container Insights enabled
- ECS service with configurable task definition
- Application Load Balancer with HTTPS support and HTTP to HTTPS redirection
- Auto-scaling based on CPU and memory utilization
- Security groups for ECS tasks and ALB
- CloudWatch logging integration
- IAM roles with least privilege permissions
- Health checks and deployment circuit breaker with rollback
- Optional DNS record creation
- Access logs for the Application Load Balancer

## Usage

```hcl
module "ecs" {
  source = "./modules/ecs"

  environment        = "dev"
  project_name       = "my-project"
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids
  service_name       = "backend-api"
  container_image    = "123456789012.dkr.ecr.us-east-1.amazonaws.com/my-app:latest"
  container_port     = 8080
  certificate_arn    = "arn:aws:acm:us-east-1:123456789012:certificate/abcd1234-ef56-gh78-ij90-klmnopqrstuv"
  alb_logs_bucket    = "my-alb-logs-bucket"
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
| public_subnet_ids | List of public subnet IDs | `list(string)` | n/a | yes |
| service_name | Name of the service | `string` | n/a | yes |
| container_image | Docker image for the container | `string` | n/a | yes |
| container_port | Port the container exposes | `number` | `80` | no |
| desired_count | Desired count of tasks | `number` | `2` | no |
| min_capacity | Minimum capacity for auto scaling | `number` | `2` | no |
| max_capacity | Maximum capacity for auto scaling | `number` | `10` | no |
| cpu | CPU units for the task | `number` | `256` | no |
| memory | Memory for the task (in MiB) | `number` | `512` | no |
| health_check_path | Path for health checks | `string` | `/health` | no |
| environment_variables | Environment variables for the container | `list(object)` | `[]` | no |
| secrets | Secrets for the container | `list(object)` | `[]` | no |
| region | AWS region | `string` | `us-east-1` | no |
| certificate_arn | ARN of the ACM certificate for HTTPS | `string` | n/a | yes |
| alb_logs_bucket | S3 bucket for ALB access logs | `string` | n/a | yes |
| create_dns_record | Whether to create a DNS record for the service | `bool` | `false` | no |
| dns_zone_id | Route53 hosted zone ID | `string` | `""` | no |
| dns_name | DNS name for the service | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| cluster_id | The ID of the ECS cluster |
| cluster_name | The name of the ECS cluster |
| service_id | The ID of the ECS service |
| service_name | The name of the ECS service |
| task_definition_arn | The ARN of the task definition |
| task_execution_role_arn | The ARN of the task execution role |
| task_role_arn | The ARN of the task role |
| alb_id | The ID of the ALB |
| alb_arn | The ARN of the ALB |
| alb_dns_name | The DNS name of the ALB |
| alb_zone_id | The zone ID of the ALB |
| target_group_arn | The ARN of the target group |
| security_group_id | The ID of the ECS tasks security group |
| alb_security_group_id | The ID of the ALB security group |
| cloudwatch_log_group_name | The name of the CloudWatch log group |
| cloudwatch_log_group_arn | The ARN of the CloudWatch log group |
| service_url | The URL of the service |
| dns_record | The DNS record for the service |

## Service Configuration

The module creates an ECS Fargate service with the following configuration:

1. ECS Cluster:
   - Container Insights enabled for enhanced monitoring
   - Named according to project and environment

2. Task Definition:
   - Fargate compatibility
   - Configurable CPU and memory
   - Container definition with health check
   - CloudWatch logging integration
   - Support for environment variables and secrets

3. ECS Service:
   - Fargate launch type with latest platform version
   - Deployment in private subnets
   - Load balancer integration
   - Deployment circuit breaker with rollback
   - Execute command capability (disabled in production)

4. Auto Scaling:
   - Target tracking scaling policies for CPU and memory utilization
   - Scale out quickly (60s cooldown) and scale in slowly (300s cooldown)
   - Target utilization set at 70%

## Load Balancer Configuration

The module sets up an Application Load Balancer with:

1. Listeners:
   - HTTPS listener on port 443 with TLS 1.2 security policy
   - HTTP listener on port 80 with redirect to HTTPS

2. Target Group:
   - Health check with configurable path
   - IP-based targets for Fargate compatibility

3. Security:
   - Deletion protection enabled in production
   - Invalid header fields dropped
   - Access logs enabled

4. DNS (Optional):
   - Route53 A record alias pointing to the ALB

## Security Features

The module implements several security features:

1. Network Security:
   - ECS tasks run in private subnets
   - ALB in public subnets with restricted security group
   - Security group for ECS tasks allows traffic only from the ALB

2. IAM Roles:
   - Task execution role with minimal permissions
   - Task role with permissions only for required services
   - Least privilege principle applied

3. HTTPS:
   - HTTPS enforced with HTTP to HTTPS redirection
   - Modern TLS security policy

## Monitoring and Logging

The module configures comprehensive monitoring and logging:

1. CloudWatch Logs:
   - Log group with 30-day retention
   - Container logs streamed to CloudWatch

2. Container Insights:
   - Enabled on the ECS cluster for detailed metrics

3. Health Checks:
   - Container health check
   - ALB target group health check

4. ALB Access Logs:
   - Stored in the specified S3 bucket

## Testing

This module includes tests using Terraform's built-in testing framework. The tests verify:

- Basic ECS service creation and configuration
- Security group and IAM role setup
- Monitoring configuration

To run the tests, navigate to the module directory and run:

```bash
terraform test
```
