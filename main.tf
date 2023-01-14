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

data "aws_ami" "latest-aws-linux-image" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-kernel*x86_64-gp2"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_key_pair" "ssh-key" {
  /*
    when using a private/public key like this instead of a .pem file,
    ssh -i ~/.ssh/id_rsa ec2-user@{public_ip}
    OR
    ssh ec2-user@{public_ip}
    because ssh pulls the default private key location
  */
  key_name   = "nginx-key"
  public_key = file(var.public_key_path)
}

resource "aws_instance" "nginx-server" {
  # amazon machine image
  ami           = data.aws_ami.latest-aws-linux-image.id
  instance_type = var.instance_type

  subnet_id              = module.nginx-subnet.subnet.id
  vpc_security_group_ids = [aws_security_group.nginx-security-group.id]
  availability_zone      = var.avail_zone

  associate_public_ip_address = true
  key_name                    = aws_key_pair.ssh-key.key_name

  /*
  # this part will only be executed once on the initial run of the server
  user_data = <<EOF
                  #!/bin/bash
                  sudo yum update -y && sudo yum install -y docker
                  sudo systemctl start docker
                  sudo usermod -aG docker ec2-user
                  sudo chmod 666 /var/run/docker.sock
                  docker run -p 8080:80 nginx
              EOF
  */

  user_data = file("entry-script.sh")

  tags = {
    Name        = "${var.env_prefix}-nginx-server"
    Environment = var.env_prefix
    Terraform   = "True"
  }
}