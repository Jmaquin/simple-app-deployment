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

