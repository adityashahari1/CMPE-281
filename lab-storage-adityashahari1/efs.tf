data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}


resource "aws_security_group" "ec2" {
  name   = "ec2-efs-clients"
  vpc_id = data.aws_vpc.default.id

  ingress {
  from_port = 22
  to_port = 22
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]  // for lab purpose allowed for all machines, should be your ip address
}

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_security_group" "efs" {
  name = "efs-mount-targets"
  vpc_id = data.aws_vpc.default.id
}

# Ingress NFS 2049 from the EC2 SG to EFS SG
resource "aws_security_group_rule" "efs_ingress_nfs" {
  type = "ingress"
  from_port = 2049
  to_port = 2049
  protocol = "tcp"
  security_group_id = aws_security_group.efs.id
  source_security_group_id = aws_security_group.ec2.id
}

resource "aws_efs_file_system" "encrypted_efs" {
  creation_token = "my-encrypted-efs-filesystem"
  encrypted = true
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"

  tags = {
    Name = "MyEncryptedEFS"
  }
}

resource "aws_efs_mount_target" "mt" {
  file_system_id = aws_efs_file_system.encrypted_efs.id
  count = 2
  subnet_id = data.aws_subnets.default.ids[count.index]
  security_groups = [aws_security_group.efs.id]
}


resource "aws_instance" "instance1" {
  ami           = "ami-0d53d72369335a9d6" # Replace with a valid AMI ID for your region (e.g., Amazon Linux 2 AMI)
  instance_type = "t3.micro"
  key_name = "key"

  subnet_id = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [aws_security_group.ec2.id]
  associate_public_ip_address = true

  user_data = <<-BASH
    #!/bin/bash
    sudo apt-get update
    sudo apt-get install -y amazon-efs-utils nfs-common
    sudo mkdir -p /mnt/efs
    sudo mount -t efs -o tls ${aws_efs_file_system.encrypted_efs.dns_name}:/ /mnt/efs
    df -h | grep efs
    echo "hello-efs" | sudo tee /mnt/efs/hello.txt
    ls -l /mnt/efs
  BASH

  tags = {
    Name = "instance1"
  }
}

resource "aws_instance" "instance2" {
  ami           = "ami-0d53d72369335a9d6" # Replace with a valid AMI ID for your region (e.g., Amazon Linux 2 AMI)
  instance_type = "t3.micro"
  key_name = "key"

  subnet_id = data.aws_subnets.default.ids[1]
  vpc_security_group_ids = [aws_security_group.ec2.id]
  associate_public_ip_address = true

  user_data = <<-BASH
    #!/bin/bash
    sudo apt-get update
    sudo apt-get install -y amazon-efs-utils nfs-common
    sudo mkdir -p /mnt/efs
    sudo mount -t efs -o tls ${aws_efs_file_system.encrypted_efs.dns_name}:/ /mnt/efs
    ls -l /mnt/efs
    cat /mnt/efs/hello.txt
  BASH

  tags = {
    Name = "instance2"
  }
}

output "instance1_public_ip" {
  value = aws_instance.instance1.public_ip
}

output "instance2_public_ip" {
  value = aws_instance.instance2.public_ip
}