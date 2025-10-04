resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh_http"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = module.vpc.vpc_id

  tags = { Name = "allow_ssh" }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_ipv4" {
  security_group_id = aws_security_group.allow_ssh.id
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "bastion_all_out" {
  security_group_id = aws_security_group.allow_ssh.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_security_group" "allow_icmp" {
  name        = "allow_icmp"
  description = "Allow all ICMP inbound"
  vpc_id      = module.vpc.vpc_id

  tags = { Name = "allow_icmp" }
}

resource "aws_vpc_security_group_ingress_rule" "icmp_ipv4" {
  security_group_id = aws_security_group.allow_icmp.id
  ip_protocol       = "icmp"
  from_port         = -1
  to_port           = -1
  cidr_ipv4         = module.vpc.vpc_cidr_block
}

resource "aws_security_group" "private_ssh_from_bastion" {
  name        = "private-ssh-from-bastion"
  description = "Allow SSH from bastion"
  vpc_id      = module.vpc.vpc_id

  tags = { Name = "private-ssh-from-bastion" }
}

resource "aws_vpc_security_group_ingress_rule" "private_ssh_from_bastion_rule" {
  security_group_id            = aws_security_group.private_ssh_from_bastion.id
  ip_protocol                  = "tcp"
  from_port                    = 22
  to_port                      = 22
  referenced_security_group_id = aws_security_group.allow_ssh.id
}

resource "aws_vpc_security_group_egress_rule" "private_ssh_all_out" {
  security_group_id = aws_security_group.private_ssh_from_bastion.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}
