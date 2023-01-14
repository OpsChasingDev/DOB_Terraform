output "ec2_public_ip" {
  value = module.nginx-server.instance.public_ip
}