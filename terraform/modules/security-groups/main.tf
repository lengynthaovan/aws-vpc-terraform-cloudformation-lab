resource "aws_security_group" "public_ec2" {
  name        = "${var.project_name}-public-ec2-sg"
  description = "Allow SSH from user IP"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.project_name}-public-ec2-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "public_ssh" {
  security_group_id = aws_security_group.public_ec2.id
  cidr_ipv4         = var.my_ip
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  description       = "Allow SSH from user public IP"
}

resource "aws_vpc_security_group_egress_rule" "public_all_outbound" {
  security_group_id = aws_security_group.public_ec2.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Allow all outbound traffic"
}

resource "aws_security_group" "private_ec2" {
  name        = "${var.project_name}-private-ec2-sg"
  description = "Allow SSH only from public EC2 security group"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.project_name}-private-ec2-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "private_ssh_from_public" {
  security_group_id            = aws_security_group.private_ec2.id
  referenced_security_group_id = aws_security_group.public_ec2.id
  from_port                    = 22
  to_port                      = 22
  ip_protocol                  = "tcp"
  description                  = "Allow SSH from public EC2 security group"
}

resource "aws_vpc_security_group_egress_rule" "private_all_outbound" {
  security_group_id = aws_security_group.private_ec2.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Allow all outbound traffic"
}