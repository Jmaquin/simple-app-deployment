mock_provider "aws" {
  mock_resource "aws_cloudwatch_log_group" {
    defaults = {
      arn = "arn:aws:logs:us-east-1:123456789012:log-group:Log/stage"
    }
  }

  mock_resource "aws_iam_role" {
    defaults = {
      arn = "arn:aws:iam::123456789012:role/role-name"
    }
  }
}

run "vpc_endpoints" {
  command = apply

  variables {
    environment        = "test"
    project_name       = "test-project"
    vpc_cidr           = "10.0.0.0/16"
    availability_zones = ["us-east-1a", "us-east-1b"]
    region             = "us-east-1"
  }

  # Verify that the S3 VPC endpoint is created
  assert {
    condition     = aws_vpc_endpoint.s3.service_name == "com.amazonaws.us-east-1.s3"
    error_message = "S3 VPC endpoint service name is incorrect"
  }

  assert {
    condition     = aws_vpc_endpoint.s3.vpc_endpoint_type == "Gateway"
    error_message = "S3 VPC endpoint type should be Gateway"
  }

  assert {
    condition     = contains(aws_vpc_endpoint.s3.route_table_ids, aws_route_table.private.id)
    error_message = "S3 VPC endpoint is not associated with the private route table"
  }

  # Verify that the ECR API VPC endpoint is created
  assert {
    condition     = aws_vpc_endpoint.ecr_api.service_name == "com.amazonaws.us-east-1.ecr.api"
    error_message = "ECR API VPC endpoint service name is incorrect"
  }

  assert {
    condition     = aws_vpc_endpoint.ecr_api.vpc_endpoint_type == "Interface"
    error_message = "ECR API VPC endpoint type should be Interface"
  }

  assert {
    condition     = aws_vpc_endpoint.ecr_api.private_dns_enabled == true
    error_message = "ECR API VPC endpoint should have private DNS enabled"
  }

  # Verify that the ECR DKR VPC endpoint is created
  assert {
    condition     = aws_vpc_endpoint.ecr_dkr.service_name == "com.amazonaws.us-east-1.ecr.dkr"
    error_message = "ECR DKR VPC endpoint service name is incorrect"
  }

  assert {
    condition     = aws_vpc_endpoint.ecr_dkr.vpc_endpoint_type == "Interface"
    error_message = "ECR DKR VPC endpoint type should be Interface"
  }

  assert {
    condition     = aws_vpc_endpoint.ecr_dkr.private_dns_enabled == true
    error_message = "ECR DKR VPC endpoint should have private DNS enabled"
  }

  # Verify that the CloudWatch Logs VPC endpoint is created
  assert {
    condition     = aws_vpc_endpoint.logs.service_name == "com.amazonaws.us-east-1.logs"
    error_message = "CloudWatch Logs VPC endpoint service name is incorrect"
  }

  assert {
    condition     = aws_vpc_endpoint.logs.vpc_endpoint_type == "Interface"
    error_message = "CloudWatch Logs VPC endpoint type should be Interface"
  }

  assert {
    condition     = aws_vpc_endpoint.logs.private_dns_enabled == true
    error_message = "CloudWatch Logs VPC endpoint should have private DNS enabled"
  }

  # Verify that the security group for VPC endpoints is correctly configured
  assert {
    condition     = aws_security_group.vpc_endpoints.vpc_id == aws_vpc.main.id
    error_message = "VPC endpoints security group is not associated with the VPC"
  }

  assert {
    condition = alltrue([
      length(aws_security_group.vpc_endpoints.ingress) == 1,
      contains([for rule in aws_security_group.vpc_endpoints.ingress : rule.from_port], 443),
      contains([for rule in aws_security_group.vpc_endpoints.ingress : rule.to_port], 443),
      contains([for rule in aws_security_group.vpc_endpoints.ingress : rule.protocol], "tcp"),
      contains([for rule in aws_security_group.vpc_endpoints.ingress[*].cidr_blocks : rule[0]], var.vpc_cidr)
    ])
    error_message = "VPC endpoints security group ingress rule is not correctly configured"
  }

  # Verify that all interface endpoints use the security group
  assert {
    condition     = contains(aws_vpc_endpoint.ecr_api.security_group_ids, aws_security_group.vpc_endpoints.id)
    error_message = "ECR API VPC endpoint is not using the VPC endpoints security group"
  }

  assert {
    condition     = contains(aws_vpc_endpoint.ecr_dkr.security_group_ids, aws_security_group.vpc_endpoints.id)
    error_message = "ECR DKR VPC endpoint is not using the VPC endpoints security group"
  }

  assert {
    condition     = contains(aws_vpc_endpoint.logs.security_group_ids, aws_security_group.vpc_endpoints.id)
    error_message = "CloudWatch Logs VPC endpoint is not using the VPC endpoints security group"
  }

  # Verify that all interface endpoints are in the private subnets
  assert {
    condition     = length(aws_vpc_endpoint.ecr_api.subnet_ids) == length(aws_subnet.private)
    error_message = "ECR API VPC endpoint is not in all private subnets"
  }

  assert {
    condition     = length(aws_vpc_endpoint.ecr_dkr.subnet_ids) == length(aws_subnet.private)
    error_message = "ECR DKR VPC endpoint is not in all private subnets"
  }

  assert {
    condition     = length(aws_vpc_endpoint.logs.subnet_ids) == length(aws_subnet.private)
    error_message = "CloudWatch Logs VPC endpoint is not in all private subnets"
  }
}
