mock_provider "aws" {
  mock_resource "aws_iam_role" {
    defaults = {
      arn  = "arn:aws:iam::123456789012:role/test-role"
      name = "test-role"
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
    certificate_arn    = "arn:aws:acm:us-east-1:123456789012:certificate/abcdef123456"
    alb_logs_bucket    = "test-project-test-alb-logs"
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
    certificate_arn    = "arn:aws:acm:us-east-1:123456789012:certificate/abcdef123456"
    alb_logs_bucket    = "test-project-test-alb-logs"
    region             = "us-east-1"
  }

  # Verify that the ALB is configured to send access logs to S3
  assert {
    condition = alltrue([
      aws_lb.main.access_logs[0].enabled == true,
      aws_lb.main.access_logs[0].bucket == var.alb_logs_bucket,
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
    certificate_arn    = "arn:aws:acm:us-east-1:123456789012:certificate/abcdef123456"
    alb_logs_bucket    = "test-project-test-alb-logs"
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

run "auto_scaling_alarms" {
  variables {
    environment        = "test"
    project_name       = "test-project"
    vpc_id             = "vpc-12345678"
    private_subnet_ids = ["subnet-12345678", "subnet-87654321"]
    public_subnet_ids  = ["subnet-abcdef12", "subnet-12abcdef"]
    service_name       = "app"
    container_image    = "nginx:latest"
    container_port     = 80
    certificate_arn    = "arn:aws:acm:us-east-1:123456789012:certificate/abcdef123456"
    alb_logs_bucket    = "test-project-test-alb-logs"
    region             = "us-east-1"
  }

  # Verify that the CPU utilization alarm is created with the correct name
  assert {
    condition     = aws_cloudwatch_metric_alarm.service_cpu_high.alarm_name == "test-project-test-app-cpu-utilization-high"
    error_message = "CPU utilization high alarm name does not match expected value"
  }

  # Verify that the CPU utilization alarm has the correct threshold
  assert {
    condition     = aws_cloudwatch_metric_alarm.service_cpu_high.threshold == 85
    error_message = "CPU utilization high alarm threshold does not match expected value"
  }

  # Verify that the CPU utilization alarm has the correct comparison operator
  assert {
    condition     = aws_cloudwatch_metric_alarm.service_cpu_high.comparison_operator == "GreaterThanOrEqualToThreshold"
    error_message = "CPU utilization high alarm comparison operator does not match expected value"
  }

  # Verify that the CPU utilization alarm has the correct metric name
  assert {
    condition     = aws_cloudwatch_metric_alarm.service_cpu_high.metric_name == "CPUUtilization"
    error_message = "CPU utilization high alarm metric name does not match expected value"
  }

  # Verify that the CPU utilization alarm has the correct namespace
  assert {
    condition     = aws_cloudwatch_metric_alarm.service_cpu_high.namespace == "AWS/ECS"
    error_message = "CPU utilization high alarm namespace does not match expected value"
  }

  # Verify that the CPU utilization alarm has the correct dimensions
  assert {
    condition = alltrue([
      aws_cloudwatch_metric_alarm.service_cpu_high.dimensions.ClusterName == aws_ecs_cluster.main.name,
      aws_cloudwatch_metric_alarm.service_cpu_high.dimensions.ServiceName == aws_ecs_service.main.name
    ])
    error_message = "CPU utilization high alarm dimensions do not match expected values"
  }

  # Verify that the CPU utilization low alarm is created with the correct name
  assert {
    condition     = aws_cloudwatch_metric_alarm.service_cpu_low.alarm_name == "test-project-test-app-cpu-utilization-low"
    error_message = "CPU utilization low alarm name does not match expected value"
  }

  # Verify that the CPU utilization low alarm has the correct threshold
  assert {
    condition     = aws_cloudwatch_metric_alarm.service_cpu_low.threshold == 10
    error_message = "CPU utilization low alarm threshold does not match expected value"
  }

  # Verify that the CPU utilization low alarm has the correct comparison operator
  assert {
    condition     = aws_cloudwatch_metric_alarm.service_cpu_low.comparison_operator == "LessThanOrEqualToThreshold"
    error_message = "CPU utilization low alarm comparison operator does not match expected value"
  }
}
