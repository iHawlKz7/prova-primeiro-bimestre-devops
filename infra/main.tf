module "vpc" {
  source = "./modules/vpc"

  project_name = var.project_name
}

module "security_group" {
  source = "./modules/security-group"

  project_name = var.project_name
  vpc_id       = module.vpc.vpc_id
  ssh_cidr     = var.ssh_cidr
}

module "rds" {
  source = "./modules/rds"

  project_name       = var.project_name
  private_subnet_ids = module.vpc.private_subnet_ids
  security_group_id  = module.security_group.rds_security_group_id

  db_name     = var.db_name
  db_username = var.db_username
  db_password = var.db_password
}

module "ec2" {
  source = "./modules/ec2"

  project_name      = var.project_name
  subnet_id         = module.vpc.public_subnet_ids[0]
  security_group_id = module.security_group.ec2_security_group_id

  db_host     = module.rds.endpoint
  db_name     = var.db_name
  db_username = var.db_username
  db_password = var.db_password

  repository_url = var.repository_url
}