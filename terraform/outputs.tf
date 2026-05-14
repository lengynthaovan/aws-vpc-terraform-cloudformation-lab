output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_id" {
  value = module.vpc.public_subnet_id
}

output "private_subnet_id" {
  value = module.vpc.private_subnet_id
}

output "internet_gateway_id" {
  value = module.vpc.internet_gateway_id
}

output "public_route_table_id" {
  value = module.vpc.public_route_table_id
}

output "private_route_table_id" {
  value = module.vpc.private_route_table_id
}

output "nat_gateway_id" {
  value = module.vpc.nat_gateway_id
}

output "nat_gateway_public_ip" {
  value = module.vpc.nat_gateway_public_ip
}

output "public_ec2_sg_id" {
  value = module.security_groups.public_ec2_sg_id
}

output "private_ec2_sg_id" {
  value = module.security_groups.private_ec2_sg_id
}

output "public_ec2_id" {
  value = module.ec2.public_ec2_id
}

output "public_ec2_public_ip" {
  value = module.ec2.public_ec2_public_ip
}

output "public_ec2_private_ip" {
  value = module.ec2.public_ec2_private_ip
}

output "private_ec2_id" {
  value = module.ec2.private_ec2_id
}

output "private_ec2_private_ip" {
  value = module.ec2.private_ec2_private_ip
}