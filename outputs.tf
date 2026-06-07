output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_id" {
  value = module.network.public_subnet_id
}

output "private_subnet_id" {
  value = module.network.private_subnet_id
}

output "internet_gateway_id" {
  value = module.network.internet_gateway_id
}

output "nat_gateway_id" {
  value = module.network.nat_gateway_id
}

output "public_route_table_id" {
  value = module.network.public_route_table_id
}

output "private_route_table_id" {
  value = module.network.private_route_table_id
}

output "public_sg_id" {
  value = module.security_groups.public_sg_id
}

output "private_sg_id" {
  value = module.security_groups.private_sg_id
}

output "public_ec2_public_ip" {
  value = module.ec2.public_ec2_public_ip
}

output "public_ec2_private_ip" {
  value = module.ec2.public_ec2_private_ip
}

output "private_ec2_private_ip" {
  value = module.ec2.private_ec2_private_ip
}