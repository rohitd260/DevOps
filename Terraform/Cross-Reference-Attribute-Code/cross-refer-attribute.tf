provider "aws" {
  region = "ap-south-1"
}

resource "aws_eip" "my_eip" {
  domain = "vpc"
}

resource "aws_security_group" "terraform_firewall" {
  name = "custom_security"
}

resource "aws_vpc_security_group_ingress_rule" "ingress1" {
  security_group_id = aws_security_group.terraform_firewall.id
  ip_protocol = "tcp"
  cidr_ipv4 = "${aws_eip.my_eip.public_ip}/32"
  from_port = 80
  to_port = 100
}