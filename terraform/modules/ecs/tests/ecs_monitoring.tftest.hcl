mock_provider "aws" {
  mock_resource "aws_iam_role" {
    defaults = {
      arn = "arn:aws:iam::123456789012:role/test-role"
    }
  }

  mock_resource "aws_iam_policy" {
    defaults = {
      arn = "arn:aws:iam::123456789012:policy/MyCustomPolicy"
    }
  }

  mock_resource "ecs_task" {
    defaults = {
      arn = "arn:aws:ecs:eu-west-3:123456789012:task/mycluster/043de9ab06bb41d29e97576f1f1d1d33"
    }
  }

  mock_resource "aws_lb" {
    defaults = {
      arn = "arn:aws:elasticloadbalancing:eu-west-3:123456789012:loadbalancer/app/my-load-balancer/1234567890123456"
    }
  }

  mock_resource "aws_lb_target_group" {
    defaults = {
      arn = "arn:aws:elasticloadbalancing:eu-west-3:123456789012:targetgroup/alb-tg/b133de1b7c64a11f"
    }
  }

  mock_resource "aws_acm_certificate" {
    defaults = {
      arn = "arn:aws:acm:eu-west-3:444455556666:certificate/certificate_ID"
    }
  }
}

run "cloudwatch_log_group_configuration" {
  command = apply

  variables {
    environment        = "test"
    project_name       = "test-project"
    vpc_id             = "vpc-12345678"
    private_subnet_ids = ["subnet-12345678", "subnet-87654321"]
    public_subnet_ids  = ["subnet-abcdef12", "subnet-12abcdef"]
    service_name       = "app"
    container_image    = "nginx:latest"
    container_port     = 80
    region             = "us-east-1"
  }

  # Verify that the CloudWatch log group is created with the correct name
  assert {
    condition     = aws_cloudwatch_log_group.ecs.name == "/ecs/test-project-test/app"
    error_message = "CloudWatch log group name does not match expected value"
  }

  # Verify that the CloudWatch log group has the correct retention period
  assert {
    condition     = aws_cloudwatch_log_group.ecs.retention_in_days == 30
    error_message = "CloudWatch log group retention period does not match expected value"
  }

  # Verify that the task definition is configured to use the CloudWatch log group
  assert {
    condition     = jsondecode(aws_ecs_task_definition.main.container_definitions)[0].logConfiguration.options["awslogs-group"] == aws_cloudwatch_log_group.ecs.name
    error_message = "Task definition is not configured to use the CloudWatch log group"
  }

  # Verify that the task definition has the correct log configuration
  assert {
    condition = alltrue([
      jsondecode(aws_ecs_task_definition.main.container_definitions)[0].logConfiguration.logDriver == "awslogs",
      jsondecode(aws_ecs_task_definition.main.container_definitions)[0].logConfiguration.options["awslogs-region"] == var.region,
      jsondecode(aws_ecs_task_definition.main.container_definitions)[0].logConfiguration.options["awslogs-stream-prefix"] == "app"
    ])
    error_message = "Task definition log configuration is not correctly configured"
  }
}

run "alb_access_logs_configuration" {
  variables {
    environment        = "test"
    project_name       = "test-project"
    vpc_id             = "vpc-12345678"
    private_subnet_ids = ["subnet-12345678", "subnet-87654321"]
    public_subnet_ids  = ["subnet-abcdef12", "subnet-12abcdef"]
    service_name       = "app"
    container_image    = "nginx:latest"
    container_port     = 80
    region             = "us-east-1"
  }

  # Verify that the ALB is configured to send access logs to S3
  assert {
    condition = alltrue([
      aws_lb.main.access_logs[0].enabled == true,
      aws_lb.main.access_logs[0].bucket == aws_s3_bucket.alb_logs.id,
      aws_lb.main.access_logs[0].prefix == "test-project-test-app-alb"
    ])
    error_message = "ALB access logs are not correctly configured"
  }
}

run "container_insights_configuration" {
  variables {
    environment        = "test"
    project_name       = "test-project"
    vpc_id             = "vpc-12345678"
    private_subnet_ids = ["subnet-12345678", "subnet-87654321"]
    public_subnet_ids  = ["subnet-abcdef12", "subnet-12abcdef"]
    service_name       = "app"
    container_image    = "nginx:latest"
    container_port     = 80
    region             = "us-east-1"
  }

  # Verify that Container Insights is enabled on the ECS cluster
  assert {
    condition = contains([
      for setting in aws_ecs_cluster.main.setting : setting.value
      if setting.name == "containerInsights"
    ], "enabled")
    error_message = "Container Insights is not enabled on the ECS cluster"
  }
}
