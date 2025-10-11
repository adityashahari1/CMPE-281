terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
}

provider "aws" {
  region = "us-west-1"
}

data "aws_vpc" "default" {
  default = true
}

resource "aws_security_group" "ssh" {
  name   = "allow-ssh"
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "example_instance" {
  ami                    = "ami-0d53d72369335a9d6"
  instance_type          = "t3.micro"
  key_name               = "key" 
  vpc_security_group_ids = [aws_security_group.ssh.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name


  associate_public_ip_address = true

  tags = {
    Name = "s3-access-instance"
  }
}

output "instance_private_ip" {
  value = aws_instance.example_instance.private_ip
}

output "instance_public_ip" {
  value = aws_instance.example_instance.public_ip
}
