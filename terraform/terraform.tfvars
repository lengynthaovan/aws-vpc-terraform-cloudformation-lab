aws_region          = "us-east-1"
project_name        = "vpc-lab"
vpc_cidr            = "10.0.0.0/16"
public_subnet_cidr  = "10.0.1.0/24"
private_subnet_cidr = "10.0.2.0/24"

# Thay bằng IP public của máy bạn
allowed_ssh_cidr = "116.108.90.195/32"

# Tên key pair trên AWS
key_name = "vockey"

instance_type = "t2.micro"