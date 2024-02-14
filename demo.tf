provider "aws" {
    region = "eu-north-1"
}

resource "aws_vpc" "my_vpc"{
    cidr_block = var.cidr_id
    tags = {
        name = "${var.project}-vpc"
        env = var.env
    }
}

resource "aws_subnet" "private_subnet"{
    vpc_id = aws_vpc.my_vpc.id
    cidr_block = var.priavte_subnet_cidr

    tags = {
      name = "${var.project}-priavte-subnet"
      env = var.env
    }
}

resource "aws_subnet" "public_subnet"{
    vpc_id = aws_vpc.my_vpc.id
    cidr_block = var.public_subnet_cidr

    tags = {
        name = "${var.project}-public-subnet"
    }
}

resource "internet_gateway" "my_igw"{
    vpc_id = aws_vpc.my_vpc.id

    tags = {
    env = var.env
    Name = "${var.project}-igw"
  }
}

resource "aws_route" "igw_route"{
    route_table_id = aws_vpc.my_vpc.default_route_table_id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = internet_gateway.my_igw.id
}

resource "aws_security_group" "my_sg" {
    name = "${var.project}-sg"
    description = "allow httpd and ssh"
    vpc_id = aws_vpc.my_vpc.id

    ingress {
        cidr_blocks = ["0.0.0.0/0"]
        protocol = "TCP"
        from_port = 22
        to_port = 22
    }

    ingress {
        cidr_blocks = ["0.0.0.0/0"]
        protocol = "TCP"
        from_port = 80
        to_port = 80
    }

    egress {
        cidr_blocks = ["0.0.0.0/0"]
        protocol = "-1"
        from_port = 0
        to_port = 0
    }

}
resource "aws_instance" "instance-1" {
    ami = var.image_id
    instance_type = var.instance_type
    key_name = var.key_pair
    vpc_security_group_ids = [aws_security_group.my_sg.id]
    tags = {
      name = "${var.project}-private-instance"
      env = var.env
    }
    subnet_id = aws_subnet.private_subnet.id
}

resource "aws_instance" "instance-2" {
    ami = var.image_id
    instance_type = var.instance_type
    key_name = var.key_pair
    vpc_security_group_ids = [aws_security_group.my_sg.id]
    tags = {
      name = "${var.project}-public-instance"
      env = var.env
    }
    subnet_id = aws_subnet.public_subnet.id
}