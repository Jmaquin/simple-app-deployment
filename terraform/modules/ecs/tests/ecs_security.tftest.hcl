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

  mock_resource "ecs_task_definition" {
    defaults = {
      arn = "arn:aws:ecs:eu-west-3:123456789012:task-definition/my-task-family:1"
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

run "security_group_configuration" {
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

  # Verify that the ECS tasks security group is created with the correct name
  assert {
    condition     = aws_security_group.ecs_tasks.name == "test-project-test-app-sg"
    error_message = "ECS tasks security group name does not match expected value"
  }

  assert {
    condition     = aws_security_group.ecs_tasks.description == "Security group for ECS tasks"
    error_message = "ECS tasks security group description does not match expected value"
  }

  assert {
    condition     = aws_security_group.ecs_tasks.vpc_id == var.vpc_id
    error_message = "ECS tasks security group is not associated with the correct VPC"
  }

  # Verify that the ECS tasks security group has the correct ingress rule
  assert {
    condition = alltrue([
      length(aws_security_group.ecs_tasks.ingress) == 1,
      contains([for rule in aws_security_group.ecs_tasks.ingress : rule.from_port], 80),
      contains([for rule in aws_security_group.ecs_tasks.ingress : rule.to_port], 80),
      contains([for rule in aws_security_group.ecs_tasks.ingress : rule.protocol], "tcp"),
      contains([
        for rule in aws_security_group.ecs_tasks.ingress : rule.description
      ], "Allow inbound traffic from ALB")
    ])
    error_message = "ECS tasks security group ingress rule is not correctly configured"
  }

  # Verify that the ECS tasks security group has the correct egress rule
  assert {
    condition = alltrue([
      length(aws_security_group.ecs_tasks.egress) == 1,
      contains([for rule in aws_security_group.ecs_tasks.egress : rule.from_port], 0),
      contains([for rule in aws_security_group.ecs_tasks.egress : rule.to_port], 0),
      contains([for rule in aws_security_group.ecs_tasks.egress : rule.protocol], "-1"),
      contains([for rule in aws_security_group.ecs_tasks.egress : rule.cidr_blocks[0]], "0.0.0.0/0"),
      contains([for rule in aws_security_group.ecs_tasks.egress : rule.description], "Allow all outbound traffic")
    ])
    error_message = "ECS tasks security group egress rule is not correctly configured"
  }

  # Verify that the ALB security group is created with the correct name
  assert {
    condition     = aws_security_group.alb.name == "test-project-test-app-alb-sg"
    error_message = "ALB security group name does not match expected value"
  }

  assert {
    condition     = aws_security_group.alb.description == "Security group for ALB"
    error_message = "ALB security group description does not match expected value"
  }

  assert {
    condition     = aws_security_group.alb.vpc_id == var.vpc_id
    error_message = "ALB security group is not associated with the correct VPC"
  }

  # Verify that the ALB security group has the correct ingress rules
  assert {
    condition = alltrue([
      length(aws_security_group.alb.ingress) == 2,
      contains([for rule in aws_security_group.alb.ingress : rule.from_port], 80),
      contains([for rule in aws_security_group.alb.ingress : rule.to_port], 80),
      contains([for rule in aws_security_group.alb.ingress : rule.from_port], 443),
      contains([for rule in aws_security_group.alb.ingress : rule.to_port], 443),
      contains([for rule in aws_security_group.alb.ingress : rule.protocol], "tcp"),
      contains([for rule in aws_security_group.alb.ingress : rule.cidr_blocks[0]], "0.0.0.0/0"),
      contains([
        for rule in aws_security_group.alb.ingress : rule.description
      ], "Allow HTTP traffic (for redirect)"),
      contains([for rule in aws_security_group.alb.ingress : rule.description], "Allow HTTPS traffic")
    ])
    error_message = "ALB security group ingress rules are not correctly configured"
  }

  # Verify that the ALB security group has the correct egress rule
  assert {
    condition = alltrue([
      length(aws_security_group.alb.egress) == 1,
      contains([for rule in aws_security_group.alb.egress : rule.from_port], 0),
      contains([for rule in aws_security_group.alb.egress : rule.to_port], 0),
      contains([for rule in aws_security_group.alb.egress : rule.protocol], "-1"),
      contains([for rule in aws_security_group.alb.egress : rule.cidr_blocks[0]], "0.0.0.0/0"),
      contains([for rule in aws_security_group.alb.egress : rule.description], "Allow all outbound traffic")
    ])
    error_message = "ALB security group egress rule is not correctly configured"
  }
}

run "iam_role_configuration" {
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

  # Verify that the ECS task execution role is created with the correct name
  assert {
    condition     = aws_iam_role.ecs_task_execution.name == "test-project-test-app-task-execution-role"
    error_message = "ECS task execution role name does not match expected value"
  }

  # Verify that the ECS task execution role has the correct trust relationship
  assert {
    condition     = can(jsondecode(aws_iam_role.ecs_task_execution.assume_role_policy))
    error_message = "ECS task execution role assume_role_policy is not valid JSON"
  }

  assert {
    condition     = jsondecode(aws_iam_role.ecs_task_execution.assume_role_policy).Statement[0].Principal.Service == "ecs-tasks.amazonaws.com"
    error_message = "ECS task execution role trust relationship does not allow ecs-tasks.amazonaws.com"
  }

  # Verify that the ECS task execution role has the correct policy attached
  assert {
    condition     = aws_iam_role_policy_attachment.ecs_task_execution.role == aws_iam_role.ecs_task_execution.name
    error_message = "ECS task execution role policy attachment is not associated with the task execution role"
  }

  assert {
    condition     = aws_iam_role_policy_attachment.ecs_task_execution.policy_arn == "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
    error_message = "ECS task execution role does not have the AmazonECSTaskExecutionRolePolicy policy attached"
  }

  # Verify that the ECS task role is created with the correct name
  assert {
    condition     = aws_iam_role.ecs_task.name == "test-project-test-app-task-role"
    error_message = "ECS task role name does not match expected value"
  }

  # Verify that the ECS task role has the correct trust relationship
  assert {
    condition     = can(jsondecode(aws_iam_role.ecs_task.assume_role_policy))
    error_message = "ECS task role assume_role_policy is not valid JSON"
  }

  assert {
    condition     = jsondecode(aws_iam_role.ecs_task.assume_role_policy).Statement[0].Principal.Service == "ecs-tasks.amazonaws.com"
    error_message = "ECS task role trust relationship does not allow ecs-tasks.amazonaws.com"
  }
}

run "custom_container_port" {
  variables {
    environment        = "test"
    project_name       = "test-project"
    vpc_id             = "vpc-12345678"
    private_subnet_ids = ["subnet-12345678", "subnet-87654321"]
    public_subnet_ids  = ["subnet-abcdef12", "subnet-12abcdef"]
    service_name       = "app"
    container_image    = "nginx:latest"
    container_port     = 8080 # Custom container port
    region             = "us-east-1"
  }

  # Verify that the ECS tasks security group ingress rule uses the custom container port
  assert {
    condition = alltrue([
      contains([for rule in aws_security_group.ecs_tasks.ingress : rule.from_port], 8080),
      contains([for rule in aws_security_group.ecs_tasks.ingress : rule.to_port], 8080)
    ])
    error_message = "ECS tasks security group ingress rule does not use the custom container port"
  }

  # Verify that the target group uses the custom container port
  assert {
    condition     = aws_lb_target_group.main.port == 8080
    error_message = "Target group port does not match custom container port"
  }

  # Verify that the container definition uses the custom container port
  assert {
    condition     = jsondecode(aws_ecs_task_definition.main.container_definitions)[0].portMappings[0].containerPort == 8080
    error_message = "Container port mapping does not match custom container port"
  }
}
