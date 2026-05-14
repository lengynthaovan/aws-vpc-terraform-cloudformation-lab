variable "project_name" {
  description = "Project name prefix"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "my_ip" {
  description = "Your public IP with /32 for SSH"
  type        = string
}