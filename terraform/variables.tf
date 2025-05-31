variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "simple-app"
}

variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "eu-west-3"
}

# VPC Variables
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones to use"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

# RDS Variables
variable "db_name" {
  description = "Name of the database"
  type        = string
  default     = "simple-app-db"
}

variable "db_username" {
  description = "Username for the database"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Password for the database"
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  description = "Instance class for the RDS instance"
  type        = string
  default     = "db.t3.medium"
}

variable "db_allocated_storage" {
  description = "Allocated storage for the RDS instance (in GB)"
  type        = number
  default     = 20
}

variable "db_max_allocated_storage" {
  description = "Maximum allocated storage for the RDS instance (in GB)"
  type        = number
  default     = 100
}

variable "db_multi_az" {
  description = "Whether to enable Multi-AZ deployment"
  type        = bool
  default     = true
}

# ECS Variables for Backend API
variable "backend_container_image" {
  description = "Container image for the backend API"
  type        = string
  default     = "nginx:latest" # Placeholder, would be replaced with actual image
}

variable "backend_container_port" {
  description = "Port the container exposes"
  type        = number
  default     = 80
}

variable "backend_desired_count" {
  description = "Desired count of tasks for the backend service"
  type        = number
  default     = 2
}

variable "backend_cpu" {
  description = "CPU units for the backend task"
  type        = number
  default     = 256
}

variable "backend_memory" {
  description = "Memory for the backend task (in MiB)"
  type        = number
  default     = 512
}

# Monitoring Variables
variable "alarm_email" {
  description = "Email address to send alarms to"
  type        = string
  default     = "alerts@example.com"
}
