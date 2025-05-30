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

run "create_ecs_cluster_and_service" {
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

  # Verify that the ECS cluster is created with the correct name
  assert {
    condition     = aws_ecs_cluster.main.name == "test-project-test-cluster"
    error_message = "ECS cluster name does not match expected value"
  }

  # Verify that container insights is enabled
  assert {
    condition     = contains([for setting in aws_ecs_cluster.main.setting : setting.value if setting.name == "containerInsights"], "enabled")
    error_message = "Container Insights is not enabled on the ECS cluster"
  }

  # Verify that the ECS service is created with the correct name
  assert {
    condition     = aws_ecs_service.main.name == "app"
    error_message = "ECS service name does not match expected value"
  }

  # Verify that the ECS service is using the correct task definition
  assert {
    condition     = aws_ecs_service.main.task_definition == aws_ecs_task_definition.main.arn
    error_message = "ECS service is not using the correct task definition"
  }

  # Verify that the ECS service has the correct desired count
  assert {
    condition     = aws_ecs_service.main.desired_count == 2
    error_message = "ECS service desired count does not match expected value"
  }

  # Verify that the ECS service is using the correct subnets
  assert {
    condition     = length(aws_ecs_service.main.network_configuration[0].subnets) == 2
    error_message = "ECS service is not using the correct number of subnets"
  }

  # Verify that the ECS service is using the correct security group
  assert {
    condition     = contains(aws_ecs_service.main.network_configuration[0].security_groups, aws_security_group.ecs_tasks.id)
    error_message = "ECS service is not using the correct security group"
  }

  # Verify that the task definition has the correct family name
  assert {
    condition     = aws_ecs_task_definition.main.family == "test-project-test-app"
    error_message = "Task definition family does not match expected value"
  }

  # Verify that the task definition has the correct CPU and memory
  assert {
    condition     = aws_ecs_task_definition.main.cpu == "256" && aws_ecs_task_definition.main.memory == "512"
    error_message = "Task definition CPU or memory does not match expected values"
  }

  # Verify that the ALB is created with the correct name
  assert {
    condition     = aws_lb.main.name == "test-project-test-app-alb"
    error_message = "ALB name does not match expected value"
  }

  # Verify that the ALB is using the correct subnets
  assert {
    condition     = length(aws_lb.main.subnets) == 2
    error_message = "ALB is not using the correct number of subnets"
  }

  # Verify that the ALB is using the correct security group
  assert {
    condition     = contains(aws_lb.main.security_groups, aws_security_group.alb.id)
    error_message = "ALB is not using the correct security group"
  }

  # Verify that the target group is created with the correct name
  assert {
    condition     = aws_lb_target_group.main.name == "test-project-test-app-tg"
    error_message = "Target group name does not match expected value"
  }

  # Verify that the target group is using the correct port
  assert {
    condition     = aws_lb_target_group.main.port == 80
    error_message = "Target group port does not match expected value"
  }

  # Verify that the target group has the correct health check path
  assert {
    condition     = aws_lb_target_group.main.health_check[0].path == "/health"
    error_message = "Target group health check path does not match expected value"
  }

  # Verify outputs
  assert {
    condition     = output.cluster_id == aws_ecs_cluster.main.id
    error_message = "cluster_id output does not match expected value"
  }

  assert {
    condition     = output.service_id == aws_ecs_service.main.id
    error_message = "service_id output does not match expected value"
  }

  assert {
    condition     = output.task_definition_arn == aws_ecs_task_definition.main.arn
    error_message = "task_definition_arn output does not match expected value"
  }

  assert {
    condition     = output.alb_dns_name == aws_lb.main.dns_name
    error_message = "alb_dns_name output does not match expected value"
  }

  assert {
    condition     = output.service_url == "https://${aws_lb.main.dns_name}"
    error_message = "service_url output does not match expected value"
  }
}

run "custom_task_configuration" {
  variables {
    environment        = "test"
    project_name       = "test-project"
    vpc_id             = "vpc-12345678"
    private_subnet_ids = ["subnet-12345678", "subnet-87654321"]
    public_subnet_ids  = ["subnet-abcdef12", "subnet-12abcdef"]
    service_name       = "app"
    container_image    = "nginx:latest"
    container_port     = 8080
    desired_count      = 3
    min_capacity       = 3
    max_capacity       = 6
    cpu                = 512
    memory             = 1024
    certificate_arn    = "arn:aws:acm:us-east-1:123456789012:certificate/abcdef123456"
    alb_logs_bucket    = "test-project-test-alb-logs"
    region             = "us-east-1"
  }

  # Verify that the ECS service has the correct desired count
  assert {
    condition     = aws_ecs_service.main.desired_count == 3
    error_message = "ECS service desired count does not match custom value"
  }

  # Verify that the task definition has the correct CPU and memory
  assert {
    condition     = aws_ecs_task_definition.main.cpu == "512" && aws_ecs_task_definition.main.memory == "1024"
    error_message = "Task definition CPU or memory does not match custom values"
  }

  # Verify that the container definition has the correct port
  assert {
    condition     = jsondecode(aws_ecs_task_definition.main.container_definitions)[0].portMappings[0].containerPort == 8080
    error_message = "Container port does not match custom value"
  }

  # Verify that the auto scaling configuration is correct
  assert {
    condition     = aws_appautoscaling_target.ecs.min_capacity == 3 && aws_appautoscaling_target.ecs.max_capacity == 6
    error_message = "Auto scaling target min/max capacity does not match custom values"
  }
}
