variable "aws_access_key" {
  description = "access key for AWS account"
}
variable "aws_secret_key" {
  description = "secret key for AWS account"
}

provider "aws" {
  region     = "us-east-1"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

variable "vpc_cidr_block" {}
variable "subnet_cidr_block" {}
variable "avail_zone" {}

resource "aws_vpc" "nginx-vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name        = "nginx-VPC"
    Environment = "dev"
    Terraform   = "True"
  }
}

resource "aws_subnet" "nginx-subnet-1" {
  vpc_id            = aws_vpc.nginx-vpc.id
  cidr_block        = var.subnet_cidr_block
  availability_zone = var.avail_zone
  tags = {
    Name        = "nginx-subnet-1"
    Environment = "dev"
    Terraform   = "True"
  }
}