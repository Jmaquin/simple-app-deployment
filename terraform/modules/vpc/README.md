# AWS VPC Terraform Module

This Terraform module creates a complete AWS VPC setup with public and private subnets, internet and NAT gateways, route tables, VPC endpoints, and VPC flow logs.

## Features

- VPC with DNS support and hostnames enabled
- Public and private subnets across multiple availability zones
- Internet Gateway for public internet access
- NAT Gateway for private subnet outbound internet access
- Route tables for public and private subnets
- VPC Flow Logs with CloudWatch integration
- VPC Endpoints for S3, ECR (API and DKR), and CloudWatch Logs
- Security group for VPC endpoints

## Usage

```hcl
module "vpc" {
  source = "./modules/vpc"

  environment        = "dev"
  project_name       = "my-project"
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = ["eu-west-3a", "eu-west-3b"]
  region             = "eu-west-3"
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
| vpc_cidr | CIDR block for the VPC | `string` | `"10.0.0.0/16"` | no |
| availability_zones | List of availability zones to use | `list(string)` | n/a | yes |
| region | AWS region to deploy resources | `string` | `"eu-west-3"` | no |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | The ID of the VPC |
| private_subnet_ids | The IDs of the private subnets |
| public_subnet_ids | The IDs of the public subnets |
| vpc_cidr | The CIDR block of the VPC |
| nat_gateway_id | The ID of the NAT Gateway |
| internet_gateway_id | The ID of the Internet Gateway |
| public_route_table_id | The ID of the public route table |
| private_route_table_id | The ID of the private route table |
| vpc_endpoint_s3_id | The ID of the S3 VPC endpoint |
| vpc_flow_log_id | The ID of the VPC Flow Log |

## Network Architecture

The module creates the following network architecture:

1. A VPC with the specified CIDR block
2. Public subnets in each availability zone (with auto-assigned public IPs)
3. Private subnets in each availability zone
4. An Internet Gateway attached to the VPC
5. A NAT Gateway in the first public subnet
6. A public route table with a route to the Internet Gateway
7. A private route table with a route to the NAT Gateway
8. VPC Endpoints for AWS services to allow private access

## VPC Endpoints

The module creates the following VPC endpoints:

- S3 Gateway Endpoint (attached to the private route table)
- ECR API Interface Endpoint (in private subnets)
- ECR DKR Interface Endpoint (in private subnets)
- CloudWatch Logs Interface Endpoint (in private subnets)

## VPC Flow Logs

The module configures VPC Flow Logs with the following settings:

- Logs all traffic (accept and reject)
- Sends logs to CloudWatch Logs
- Creates a dedicated IAM role with appropriate permissions
- Sets a 30-day log retention period

## Testing

This module includes comprehensive tests using Terraform's built-in testing framework. The tests verify:

- Basic VPC functionality and subnet creation
- VPC Endpoints configuration
- VPC Flow Logs setup

To run the tests, navigate to the module directory and run:

```bash
terraform test
```
