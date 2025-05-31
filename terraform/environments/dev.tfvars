environment  = "dev"
project_name = "simple-app"
region       = "eu-north-1"

# VPC Variables
vpc_cidr           = "10.0.0.0/16"
availability_zones = ["eu-north-1a", "eu-north-1b"]

# RDS Variables
db_name                  = "simple-app-db"
db_username              = "dbadmin"
db_password              = ""
db_instance_class        = "db.t3.medium"
db_allocated_storage     = 5
db_max_allocated_storage = 10
db_multi_az              = false

# ECS Variables for Backend API
backend_container_image = "nginx:latest"
backend_container_port  = 80
backend_desired_count   = 1
backend_cpu             = 256
backend_memory          = 512

# Monitoring Variables
alarm_email = "alerts@example.com"
