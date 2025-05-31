# Simple Application Infrastructure

This repository contains the infrastructure code for a basic application. The infrastructure is designed to be secure, scalable, and compliant with data regulations.

## Architecture Overview

The infrastructure is built on AWS and consists of the following components:

- **Networking**: A private VPC with public and private subnets across multiple availability zones
- **Database**: Amazon RDS for PostgreSQL with encryption and automated backups
- **Backend API**: ECS Fargate service with auto-scaling
- **Monitoring**: CloudWatch dashboards, alarms, and log aggregation
- **Security**: Encryption at rest and in transit, IAM roles with least privilege, VPC endpoints

For a detailed architecture description, see [Architecture Document](docs/architecture.md).

## Infrastructure as Code

The infrastructure is defined using Terraform with a modular approach:

- **VPC Module**: Creates the networking infrastructure
- **RDS Module**: Creates the PostgreSQL database
- **ECS Module**: Creates the backend API service
- **Monitoring Module**: Creates CloudWatch dashboards, alarms, and log aggregation

## CI/CD Pipeline

The repository includes a GitHub Actions workflow that:

1. Validates Terraform code
2. Unit Test Terraform modules
3. Run Terraform plan on dev environment

## Setup Instructions

### Prerequisites

- AWS Account
- Terraform 1.6.0 or later
- AWS CLI configured with appropriate credentials

### Initial Setup

1. Create an S3 bucket and DynamoDB table for Terraform state:

```bash
aws s3 mb s3://simple-app-deployment-terraform-state
aws dynamodb create-table \
    --table-name simple-app-deployment-terraform-locks \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST
```

2. Configure GitHub Secrets for CI/CD:

- `AWS_ACCESS_KEY_ID`: AWS access key with permissions to create resources
- `AWS_SECRET_ACCESS_KEY`: AWS secret key

### Local Development

1. Clone the repository:

```bash
git https://github.com/Jmaquin/simple-app-deployment.git
cd simple-app-deployment
```

2. Initialize Terraform:

```bash
cd terraform
terraform init \
    -backend-config="bucket=simple-app-deployment-terraform-state" \
    -backend-config="key=terraform.tfstate" \
    -backend-config="region=eu-west-3" \
    -backend-config="dynamodb_table=simple-app-deployment-terraform-locks"
```

3. Create a `terraform.tfvars` file with sensitive variables:

```
db_password = "your-secure-password"
```

4. Plan and apply changes:

```bash
# For development environment
terraform plan -var-file=environments/dev.tfvars
terraform apply -var-file=environments/dev.tfvars
```

## Tradeoffs & Limitations

- **Simplified AI Component**: The current implementation focuses on the backend API and doesn't include specialized GPU instances for AI workloads.
- **Frontend Deployment**: The frontend deployment is not included in this version but could be added using CloudFront and S3.

## Next Steps

1. Implement Terraform state management using s3 and dynamoDB
2. Provision infrastructure with terraform apply and Github Actions
3. Implement the AI component with GPU support 
4. Add the frontend deployment using CloudFront and S3 
5. Enhance security with AWS WAF and Shield 
6. Implement blue/green deployments for zero-downtime updates 
7. Improve automated testing for infrastructure 
8. Implement cost optimization strategies 
9. Create a disaster recovery plan
