locals {
  secret_arns = [for secret in var.secrets : secret.valueFrom]
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "service_name" {
  description = "Name of the service"
  type        = string
}

variable "container_image" {
  description = "Docker image for the container"
  type        = string
}

variable "container_port" {
  description = "Port the container exposes"
  type        = number
  default     = 80
}

variable "desired_count" {
  description = "Desired count of tasks"
  type        = number
  default     = 2
}

variable "min_capacity" {
  description = "Minimum capacity for auto scaling"
  type        = number
  default     = 2
}

variable "max_capacity" {
  description = "Maximum capacity for auto scaling"
  type        = number
  default     = 10
}

variable "cpu" {
  description = "CPU units for the task"
  type        = number
  default     = 256
}

variable "memory" {
  description = "Memory for the task (in MiB)"
  type        = number
  default     = 512
}

variable "health_check_path" {
  description = "Path for health checks"
  type        = string
  default     = "/health"
}

variable "environment_variables" {
  description = "Environment variables for the container"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "secrets" {
  description = "Secrets for the container"
  type = list(object({
    name      = string
    valueFrom = string
  }))
  default = []
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "certificate_arn" {
  description = "ARN of the ACM certificate for HTTPS"
  type        = string
}

variable "alb_logs_bucket" {
  description = "S3 bucket for ALB access logs"
  type        = string
}

variable "create_dns_record" {
  description = "Whether to create a DNS record for the service"
  type        = bool
  default     = false
}

variable "dns_zone_id" {
  description = "Route53 hosted zone ID"
  type        = string
  default     = ""
}

variable "dns_name" {
  description = "DNS name for the service"
  type        = string
  default     = ""
}
