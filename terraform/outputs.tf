# VPC Outputs
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "The IDs of the private subnets"
  value       = module.vpc.private_subnet_ids
}

output "public_subnet_ids" {
  description = "The IDs of the public subnets"
  value       = module.vpc.public_subnet_ids
}

# RDS Outputs
output "db_instance_endpoint" {
  description = "The connection endpoint for the RDS instance"
  value       = module.rds.db_instance_endpoint
}

output "db_instance_id" {
  description = "The ID of the RDS instance"
  value       = module.rds.db_instance_id
}

# ECS Outputs
output "backend_api_url" {
  description = "The URL of the backend API"
  value       = module.backend_api.service_url
}

output "backend_api_cluster_name" {
  description = "The name of the ECS cluster for the backend API"
  value       = module.backend_api.cluster_name
}

# Monitoring Outputs
output "cloudwatch_log_group_name" {
  description = "The name of the CloudWatch log group"
  value       = module.monitoring.log_group_name
}

output "alarm_topic_arn" {
  description = "The ARN of the SNS topic for alarms"
  value       = module.monitoring.alarm_topic_arn
}
