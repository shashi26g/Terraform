provider "aws" {
  region = "ap-south-1"
}

resource "aws_instance" "app_compute_node" {
  ami           = "ami-03f4878755434977f" # Verified Amazon Linux 2023 AMI for ap-south-1
  instance_type = "t3.micro"              # Eligible for Free Tier

  tags = {
    Name        = "production-compute-node"
    Provisioner = "Terraform"
    Owner       = "Shashidara"
  }
}

resource "aws_s3_bucket" "secure_storage_bucket" {
  bucket        = "enterprise-data-lake-shashidara-2026-secure"
  force_destroy = true

  tags = {
    Name        = "enterprise-data-lake"
    Environment = "Production"
    Owner       = "Shashidara"
  }
}
