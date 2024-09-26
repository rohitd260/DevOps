provider "aws" {
  region = "ap-south-1"
}

resource "aws_eip" "my_eip" {
  domain = "vpc"
}

output "Firewall_public_id" {
    value = "${aws_eip.my_eip.public_ip}"
}