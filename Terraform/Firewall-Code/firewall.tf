resource "aws_security_group" "my_firewall" {
  name = "terraform_firewall"
  description = "allow TLS inbound traffic and all outbound traffic"
  
  tags = {
    name="allows TLS"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ingress1" {
  security_group_id = aws_security_group.my_firewall.id
  cidr_ipv4   = "10.0.0.0/8"
  from_port   = 80
  ip_protocol = "tcp"
  to_port     = 80
}

resource "aws_vpc_security_group_egress_rule" "egrees1" {
  security_group_id = aws_security_group.my_firewall.id
  cidr_ipv4   = "10.0.0.0/8"
  from_port   = 80
  ip_protocol = "tcp"
  to_port     = 80
}
