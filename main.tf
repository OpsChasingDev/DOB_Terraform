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
variable "instance_type" {}
variable "public_key_path" {}
variable "private_key_location" {}

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

output "aws_ami_id" {
  value = data.aws_ami.latest-aws-linux-image.id
}
output "ec2_public_ip" {
  value = aws_instance.nginx-server.public_ip
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

  subnet_id              = aws_subnet.nginx-subnet-1.id
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

  # connection and provisioner used to connect to server via SSH or WinRM
  # THESE ARE NOT RECOMMENDED TO USE - NOT IDEMPOTENT AND LIMITED IN FUNCTIONALITY
  connection {
    type        = "ssh" # winrm is also a type
    host        = self.public_ip
    user        = "ec2-user"
    private_key = file(var.private_key_location)
  }

  provisioner "file" {
    source      = "entry-script.sh"
    destination = "/hom/ec2-user/entry-script.sh"
  }

  provisioner "remote-exec" {
    # inline is for direct execution
    inline = [
      "export ENV=dev",
      "mkdir newdir",
    ]
    # a script can be specified with the "file" provisioner to copy a script to the server and execute it
    script = file("entry-script.sh")
  }

  provisioner "local-exec" {
    # these commands will be executed locally from the machine you run terraform commands
    command = "echo ${self.public_ip} > output.txt"
  }

  tags = {
    Name        = "${var.env_prefix}-nginx-server"
    Environment = var.env_prefix
    Terraform   = "True"
  }
}