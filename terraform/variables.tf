variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name prefix"
  type        = string
  default     = "lab"
}

variable "my_ip" {
  description = "Your public IP for SSH access"
  type        = string
}