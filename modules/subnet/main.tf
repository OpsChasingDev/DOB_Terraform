resource "aws_subnet" "nginx-subnet-1" {
  vpc_id            = var.vpc_id
  cidr_block        = var.subnet_cidr_block
  availability_zone = var.avail_zone
  tags = {
    Name        = "${var.env_prefix}-nginx-subnet-1"
    Environment = var.env_prefix
    Terraform   = "True"
  }
}

resource "aws_route_table" "nginx-route-table" {
  vpc_id = var.vpc_id
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
  vpc_id = var.vpc_id
  tags = {
    Name        = "${var.env_prefix}-nginx-igw"
    Environment = var.env_prefix
    Terraform   = "True"
  }
}