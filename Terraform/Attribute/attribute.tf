provider "aws" {
  region = "ap-south-1"
}

resource "aws_eip" "my_eip" {
  domain = "vpc"
}

resource "aws_instance" "web" {
    ami = "ami-08718895af4dfa033"
    instance_type = "t2.micro"
}

