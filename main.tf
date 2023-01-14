provider "aws" {
  region     = "us-east-1"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

module "nginx-subnet" {
  source            = "./modules/subnet"
  subnet_cidr_block = var.subnet_cidr_block
  avail_zone        = var.avail_zone
  env_prefix        = var.env_prefix
  vpc_id            = aws_vpc.nginx-vpc.id
}

module "nginx-server" {
  source          = "./modules/webserver"
  vpc_id          = aws_vpc.nginx-vpc.id
  my_ip           = var.my_ip
  env_prefix      = var.env_prefix
  public_key_path = var.public_key_path
  instance_type   = var.instance_type
  subnet_id       = module.nginx-subnet.subnet.id
  avail_zone      = var.avail_zone
}

resource "aws_vpc" "nginx-vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name        = "${var.env_prefix}-nginx-VPC"
    Environment = var.env_prefix
    Terraform   = "True"
  }
}

# we don't want to use the default route table for our subnet as a best practice
resource "aws_route_table_association" "nginx-rtb-subnet" {
  subnet_id      = module.nginx-subnet.subnet.id
  route_table_id = module.nginx-subnet.route_table.id
}