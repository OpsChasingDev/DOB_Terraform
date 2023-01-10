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

variable "vpc_cidr_block" {
  description = "vpc cidr block"
}
variable "subnet_cidr_block" {
  description = "subnet cidr block"
  default = ""
  type = string
}

resource "aws_vpc" "development-vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name = "VPC"
    Environment = "dev"
    Terraform = "True"
  }
}

resource "aws_subnet" "development-subnet" {
  vpc_id = aws_vpc.development-vpc.id
  cidr_block = var.subnet_cidr_block
  availability_zone = "us-east-1a"
  tags = {
    Name = "Subnet"
    Environment = "dev"
    Terraform = "True"
  }
}