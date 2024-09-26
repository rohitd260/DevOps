provider "aws" {
  region = "ap-south-1"
}

resource "aws_eip" "my_eip" {
  domain = "vpc"
}

//Code only print public ip id on screen for Elastic Ip resouce
output "Firewall_public_id" {
    value = "${aws_eip.my_eip.public_ip}"
}

//code print all the attribute populated with the Elastic Ip resource

output "FireWall_Attributes" {
    value = "${aws_eip.my_eip}"
}
