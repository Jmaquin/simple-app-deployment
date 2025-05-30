# Variables for Monitoring Module

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

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "alarm_email" {
  description = "Email address to send alarms to"
  type        = string
}

variable "log_retention_days" {
  description = "Number of days to retain logs in CloudWatch"
  type        = number
  default     = 30
}

variable "alarm_cpu_threshold" {
  description = "Threshold for CPU utilization alarm"
  type        = number
  default     = 80
}

variable "alarm_memory_threshold" {
  description = "Threshold for memory utilization alarm"
  type        = number
  default     = 80
}

variable "alarm_storage_threshold" {
  description = "Threshold for storage space alarm (in bytes)"
  type        = number
  default     = 5000000000 # 5GB
}

variable "alarm_5xx_threshold" {
  description = "Threshold for 5XX error count alarm"
  type        = number
  default     = 10
}

variable "dashboard_period" {
  description = "Period for dashboard metrics (in seconds)"
  type        = number
  default     = 300 # 5 minutes
}

variable "enable_s3_log_export" {
  description = "Whether to enable exporting logs to S3"
  type        = bool
  default     = true
}

variable "log_lifecycle_transition_standard_ia_days" {
  description = "Number of days before transitioning logs to STANDARD_IA storage"
  type        = number
  default     = 30
}

variable "log_lifecycle_transition_glacier_days" {
  description = "Number of days before transitioning logs to GLACIER storage"
  type        = number
  default     = 90
}

variable "log_lifecycle_expiration_days" {
  description = "Number of days before expiring logs"
  type        = number
  default     = 365
}
