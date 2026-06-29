terraform {
  backend "s3" {
    bucket  = "nt548-22521648-lab02-tfstate"
    key     = "terraform/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}