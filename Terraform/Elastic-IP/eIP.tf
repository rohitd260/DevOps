provider "aws" {
  region = "ap-south-1"
}

// aws_eip = aws elastic ip
resource "aws_eip" "name" {
  domain = "vpc"
}