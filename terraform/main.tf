module "vpc" {
  source = "./modules/vpc"

  environment        = var.environment
  project_name       = var.project_name
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  region             = var.region
}

module "rds" {
  source = "./modules/rds"

  environment        = var.environment
  project_name       = var.project_name
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  db_name            = var.db_name
  db_username        = var.db_username
  db_password        = var.db_password
  db_instance_class  = var.db_instance_class
}

module "backend_api" {
  source = "./modules/ecs"

  environment        = var.environment
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids
  container_image    = var.backend_container_image
  container_port     = var.backend_container_port
  desired_count      = var.backend_desired_count
  cpu                = var.backend_cpu
  memory             = var.backend_memory
  service_name       = "backend-api"
  project_name       = var.project_name
  health_check_path  = "/health"
  region             = var.region
  depends_on = [
    module.rds
  ]
}

module "monitoring" {
  source = "./modules/monitoring"

  environment  = var.environment
  project_name = var.project_name
  alarm_email  = var.alarm_email
  region       = var.region
  depends_on = [
    module.rds,
    module.backend_api
  ]
}
