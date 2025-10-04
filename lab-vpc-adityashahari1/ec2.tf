resource "aws_eip" "app_eip" {
  domain = "vpc"
  tags = { Name = "app-eip" }
}

resource "aws_eip_association" "app_eip_assoc" {
  allocation_id = aws_eip.app_eip.id
  instance_id   = aws_instance.app_server.id
}

output "public_instance_public_ip" {
  value = aws_eip.app_eip.public_ip
}

resource "aws_instance" "app_server" {
  ami                         = "ami-0d53d72369335a9d6"
  instance_type               = "t3.micro"
  subnet_id                   = module.vpc.public_subnets[0]
  vpc_security_group_ids      = [aws_security_group.allow_ssh.id]
  associate_public_ip_address = true
  key_name                    = "key"

  tags = { Name = "public-ec2" }
}

resource "aws_instance" "private_server" {
  ami                         = "ami-0d53d72369335a9d6"
  instance_type               = "t3.micro"
  subnet_id                   = module.vpc.private_subnets[0]
  vpc_security_group_ids      = [
    aws_security_group.allow_icmp.id,
    aws_security_group.private_ssh_from_bastion.id
  ]
  associate_public_ip_address = false
  key_name                    = "key"

  tags = { Name = "private-ec2" }
}

output "private_instance_private_ip" {
  value = aws_instance.private_server.private_ip
}
