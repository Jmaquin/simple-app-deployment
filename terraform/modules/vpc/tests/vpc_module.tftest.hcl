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

run "create_vpc" {
	command = apply

	variables {
		environment  = "test"
		project_name = "test-project"
		vpc_cidr     = "10.0.0.0/16"
		availability_zones = ["us-east-1a", "us-east-1b"]
		region       = "us-east-1"
	}

	# Verify that the VPC is created with the correct CIDR block
	assert {
		condition     = aws_vpc.main.cidr_block == "10.0.0.0/16"
		error_message = "VPC CIDR block does not match expected value"
	}

	# Verify that DNS support and hostnames are enabled
	assert {
		condition     = aws_vpc.main.enable_dns_support == true && aws_vpc.main.enable_dns_hostnames == true
		error_message = "VPC DNS settings are not configured correctly"
	}

	# Verify that the correct number of public subnets are created
	assert {
		condition     = length(aws_subnet.public) == 2
		error_message = "Expected 2 public subnets but got ${length(aws_subnet.public)}"
	}

	# Verify that the correct number of private subnets are created
	assert {
		condition     = length(aws_subnet.private) == 2
		error_message = "Expected 2 private subnets but got ${length(aws_subnet.private)}"
	}

	# Verify that the Internet Gateway is attached to the VPC
	assert {
		condition     = aws_internet_gateway.main.vpc_id == aws_vpc.main.id
		error_message = "Internet Gateway is not attached to the VPC"
	}

	# Verify that the NAT Gateway is created in the first public subnet
	assert {
		condition     = aws_nat_gateway.main.subnet_id == aws_subnet.public[0].id
		error_message = "NAT Gateway is not in the first public subnet"
	}

	# Verify that the public route table has a route to the Internet Gateway
	assert {
		condition = alltrue([
			length(aws_route_table.public.route) == 1,
			contains([for route in aws_route_table.public.route : route.gateway_id], aws_internet_gateway.main.id)
		])
		error_message = "Public route table does not have a route to the Internet Gateway"
	}

	# Verify that the private route table has a route to the NAT Gateway
	assert {
		condition = alltrue([
			length(aws_route_table.public.route) == 1,
			contains([for route in aws_route_table.private.route : route.nat_gateway_id], aws_nat_gateway.main.id)
		])
		error_message = "Private route table does not have a route to the NAT Gateway"
	}

	# Verify outputs
	assert {
		condition     = length(output.public_subnet_ids) == 2
		error_message = "Expected 2 public subnet IDs in output"
	}

	assert {
		condition     = length(output.private_subnet_ids) == 2
		error_message = "Expected 2 private subnet IDs in output"
	}

	assert {
		condition     = output.vpc_cidr == "10.0.0.0/16"
		error_message = "VPC CIDR output does not match expected value"
	}
}

run "custom_vpc_cidr" {
	variables {
		environment  = "test"
		project_name = "test-project"
		vpc_cidr = "172.16.0.0/16"  # Custom CIDR
		availability_zones = ["us-east-1a", "us-east-1b"]
		region       = "us-east-1"
	}

	assert {
		condition     = aws_vpc.main.cidr_block == "172.16.0.0/16"
		error_message = "VPC CIDR block does not match custom value"
	}

	# Verify that subnet CIDRs are derived from the VPC CIDR
	assert {
		condition     = aws_subnet.public[0].cidr_block == cidrsubnet("172.16.0.0/16", 8, 0)
		error_message = "Public subnet CIDR is not correctly derived from VPC CIDR"
	}

	assert {
		condition     = aws_subnet.private[0].cidr_block == cidrsubnet("172.16.0.0/16", 8, 2)
		error_message = "Private subnet CIDR is not correctly derived from VPC CIDR"
	}
}

# Test case for VPC with different number of availability zones
run "three_availability_zones" {
	variables {
		environment  = "test"
		project_name = "test-project"
		vpc_cidr     = "10.0.0.0/16"
		availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]  # Three AZs
		region       = "us-east-1"
	}

	assert {
		condition     = length(aws_subnet.public) == 3
		error_message = "Expected 3 public subnets but got ${length(aws_subnet.public)}"
	}

	assert {
		condition     = length(aws_subnet.private) == 3
		error_message = "Expected 3 private subnets but got ${length(aws_subnet.private)}"
	}

	assert {
		condition     = length(output.public_subnet_ids) == 3
		error_message = "Expected 3 public subnet IDs in output"
	}

	assert {
		condition     = length(output.private_subnet_ids) == 3
		error_message = "Expected 3 private subnet IDs in output"
	}
}
