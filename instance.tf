provider "aws" {
    region = "eu-north-1"
}

resource "aws_instance" "my-instance" {
    ami = "ami-0014ce3e52359afbd"
    instance_type = "t3.micro"
    key_name = "bigkey"
    vpc_security_group_ids = ["sg-06f07706cd44bb966"]
    tags = {
        Name = "instance-1"
    }
}
