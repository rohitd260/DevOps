provider "aws" {
  region = "ap-south-1"
}

//Resource for security group
resource "aws_security_group" "firewall_grp" {
  name        = "terraform_firewall"
  description = "Managed from the Terraform"
}

//ip for ingress rule will fetch from anoter tf fire and managaed at terraform plan command
resource "aws_vpc_security_group_ingress_rule" "app-port" {
  security_group_id = aws_security_group.firewall_grp.id
  ip_protocol       = "tcp"
  cidr_ipv4         = var.vpn_id_from_another_tf_file
  from_port         = 8080
  to_port           = 8080
}
resource "aws_vpc_security_group_ingress_rule" "ssh-port" {
  security_group_id = aws_security_group.firewall_grp.id
  ip_protocol       = "tcp"
  cidr_ipv4         = var.vpn_id_from_another_tf_file
  from_port         = 80
  to_port           = 100
}

resource "aws_vpc_security_group_ingress_rule" "ftp-port" {
  security_group_id = aws_security_group.firewall_grp.id
  ip_protocol       = "tcp"
  cidr_ipv4 = var.vpn_id_from_another_tf_file
  from_port = 1032
  to_port = 1234
  }

