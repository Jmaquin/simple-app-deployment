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

run "vpc_flow_logs" {
	command = apply

	variables {
		environment  = "test"
		project_name = "test-project"
		vpc_cidr     = "10.0.0.0/16"
		availability_zones = ["us-east-1a", "us-east-1b"]
		region       = "us-east-1"
	}

	# Verify that the CloudWatch log group for flow logs is created
	assert {
		condition     = aws_cloudwatch_log_group.flow_log.name == "/aws/vpc/flow-log/test-project-test"
		error_message = "CloudWatch log group name is incorrect"
	}

	assert {
		condition     = aws_cloudwatch_log_group.flow_log.retention_in_days == 30
		error_message = "CloudWatch log group retention period should be 30 days"
	}

	# Verify that the IAM role for flow logs is created
	assert {
		condition     = aws_iam_role.flow_log.name == "test-project-test-flow-log-role"
		error_message = "IAM role name is incorrect"
	}

	# Verify that the IAM role has the correct trust relationship
	assert {
		condition = can(jsondecode(aws_iam_role.flow_log.assume_role_policy))
		error_message = "IAM role assume_role_policy is not valid JSON"
	}

	assert {
		condition     = jsondecode(aws_iam_role.flow_log.assume_role_policy).Statement[0].Principal.Service == "vpc-flow-logs.amazonaws.com"
		error_message = "IAM role trust relationship does not allow vpc-flow-logs.amazonaws.com"
	}

	# Verify that the IAM policy for flow logs is created
	assert {
		condition     = aws_iam_role_policy.flow_log.name == "test-project-test-flow-log-policy"
		error_message = "IAM policy name is incorrect"
	}

	assert {
		condition     = aws_iam_role_policy.flow_log.role == aws_iam_role.flow_log.id
		error_message = "IAM policy is not attached to the flow log role"
	}

	# Verify that the IAM policy has the correct permissions
	assert {
		condition = can(jsondecode(aws_iam_role_policy.flow_log.policy))
		error_message = "IAM policy is not valid JSON"
	}

	assert {
		condition = contains(jsondecode(aws_iam_role_policy.flow_log.policy).Statement[0].Action, "logs:CreateLogGroup")
		error_message = "IAM policy does not allow logs:CreateLogGroup"
	}

	assert {
		condition = contains(jsondecode(aws_iam_role_policy.flow_log.policy).Statement[0].Action, "logs:CreateLogStream")
		error_message = "IAM policy does not allow logs:CreateLogStream"
	}

	assert {
		condition = contains(jsondecode(aws_iam_role_policy.flow_log.policy).Statement[0].Action, "logs:PutLogEvents")
		error_message = "IAM policy does not allow logs:PutLogEvents"
	}

	# Verify that the VPC flow log is created
	assert {
		condition     = aws_flow_log.main.log_destination == aws_cloudwatch_log_group.flow_log.arn
		error_message = "VPC flow log destination is incorrect"
	}

	assert {
		condition     = aws_flow_log.main.log_destination_type == "cloud-watch-logs"
		error_message = "VPC flow log destination type should be cloud-watch-logs"
	}

	assert {
		condition     = aws_flow_log.main.traffic_type == "ALL"
		error_message = "VPC flow log traffic type should be ALL"
	}

	assert {
		condition     = aws_flow_log.main.vpc_id == aws_vpc.main.id
		error_message = "VPC flow log is not associated with the VPC"
	}

	assert {
		condition     = aws_flow_log.main.iam_role_arn == aws_iam_role.flow_log.arn
		error_message = "VPC flow log is not using the flow log IAM role"
	}
}
