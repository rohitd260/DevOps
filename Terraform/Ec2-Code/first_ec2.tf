provider "aws" {
    region = "ap-south-1"
    access_key = "my_access_key"
    secret_key = "my_secret_key"
}
resource "aws_instance" "myec2" {
  ami = "ami-0871889yiaei99229"
  instance_type = "t2.micro"
}