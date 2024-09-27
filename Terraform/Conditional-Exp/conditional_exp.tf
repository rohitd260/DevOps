provider "aws" {
    region = "ap-south-1"
}

variable "ENV" {
    default = "developement"
}

resource "aws_instance" "myec2" {
  ami = "ami-08718895af4dfa033"
  instance_type = var.ENV == "development" ? "t2.micro" : "t2.large"
}