module "vpc" {
  source       = "./modules/vpc"
  project_name = var.project_name
}

module "security_groups" {
  source       = "./modules/security-groups"
  project_name = var.project_name
  vpc_id       = module.vpc.vpc_id
  my_ip        = var.my_ip
}

module "ec2" {
  source = "./modules/ec2"

  project_name      = var.project_name
  public_subnet_id  = module.vpc.public_subnet_id
  private_subnet_id = module.vpc.private_subnet_id
  public_ec2_sg_id  = module.security_groups.public_ec2_sg_id
  private_ec2_sg_id = module.security_groups.private_ec2_sg_id
  key_name          = var.key_name
  instance_type     = var.instance_type
}