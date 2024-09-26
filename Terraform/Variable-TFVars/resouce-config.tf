provider "aws" {
  region = var.my_region  //refering from the variable tf file
}

resource "aws_instance" "vm1" {
    ami = var.ami_id  //refering from the varibable tf file
    instance_type = var.ec2_instance_type // refering from the variable tf file
}
