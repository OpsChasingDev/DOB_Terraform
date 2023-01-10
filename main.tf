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
variable "env_prefix" {}
variable "my_ip" {}

resource "aws_vpc" "nginx-vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name        = "${var.env_prefix}-nginx-VPC"
    Environment = var.env_prefix
    Terraform   = "True"
  }
}

resource "aws_subnet" "nginx-subnet-1" {
  vpc_id            = aws_vpc.nginx-vpc.id
  cidr_block        = var.subnet_cidr_block
  availability_zone = var.avail_zone
  tags = {
    Name        = "${var.env_prefix}-nginx-subnet-1"
    Environment = var.env_prefix
    Terraform   = "True"
  }
}

resource "aws_route_table" "nginx-route-table" {
  vpc_id = aws_vpc.nginx-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.nginx-igw.id
  }
  tags = {
    Name        = "${var.env_prefix}-nginx-route-table"
    Environment = var.env_prefix
    Terraform   = "True"
  }
}

resource "aws_internet_gateway" "nginx-igw" {
  vpc_id = aws_vpc.nginx-vpc.id
  tags = {
    Name        = "${var.env_prefix}-nginx-igw"
    Environment = var.env_prefix
    Terraform   = "True"
  }
}

# we don't want to use the default route table for our subnet as a best practice
resource "aws_route_table_association" "nginx-rtb-subnet" {
  subnet_id      = aws_subnet.nginx-subnet-1.id
  route_table_id = aws_route_table.nginx-route-table.id
}

resource "aws_security_group" "nginx-security-group" {
  name   = "nginx-security-group"
  vpc_id = aws_vpc.nginx-vpc.id

  # ssh
  ingress {
    # from_port and to_port specify a range, e.g. from port 56000-58000
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }
  # 8080
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # configured for "any"
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    prefix_list_ids = []
  }

  tags = {
    Name        = "${var.env_prefix}-nginx-security-group"
    Environment = var.env_prefix
    Terraform   = "True"
  }

}