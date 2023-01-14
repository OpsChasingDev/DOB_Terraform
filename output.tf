output "aws_ami_id" {
  value = data.aws_ami.latest-aws-linux-image.id
}

output "ec2_public_ip" {
  value = aws_instance.nginx-server.public_ip
}