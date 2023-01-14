provider "aws" {
  region = "us-east-1"
}

variable "vpc_cidr_block" {}
variable "private_subnet_cidr_blocks" {}
variable "public_subnet_cidr_blocks" {}

data "aws_availability_zones" "azs" {

}

module "myapp-vpc" {
  # gets downloaded upon running terraform init
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.19.0"

  name            = "myapp-vpc"
  cidr            = var.vpc_cidr_block
  private_subnets = var.private_subnet_cidr_blocks
  public_subnets  = var.public_subnet_cidr_blocks
  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones
  azs = data.aws_availability_zones.azs.names

  # setting this as true just for transparency, this is the default
  enable_nat_gateway = true
  # makes all private subnets route their internet traffic through this gateway
  single_nat_gateway   = true
  enable_dns_hostnames = true

  tags = {
    # this unusual tag is going to be used so we can reference the cluster programmatically
    "kubernetes.io/cluster/myapp-eks-cluster" = "shared"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/myapp-eks-cluster" = "shared"
    "kubernetes.io/role/elb"                  = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/myapp-eks-cluster" = "shared"
    "kubernetes.io/role/internal-elb"         = 1
  }
}