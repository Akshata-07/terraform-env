provider "aws" {
    region = "eu-north-1"
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "eks_role" {
  name               = "eks-cluster-example"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "example-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_role.name
}


resource "aws_vpc" "my_vpc" {
    cidr_block = var.cidr_id
    tags = {
        Name = "${var.project}-vpc"
        env = var.env
    }
}

resource "aws_subnet" "private_subnet" {
    vpc_id     = aws_vpc.my_vpc.id
    cidr_block = var.private_subnet_cidr

    tags = {
        env = var.env
        Name = "${var.project}-private-subnet"
    }
}

resource "aws_subnet" "public_subnet" {
    vpc_id     = aws_vpc.my_vpc.id
    cidr_block = var.public_subnet_cidr
    map_public_ip_on_launch = true
    tags = {
        env = var.env
        Name = "${var.project}-public-subnet"
    }
}

resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    env = var.env
    Name = "${var.project}-igw"
  }
}

resource "aws_route" "igw_route" {
  route_table_id            = aws_vpc.my_vpc.default_route_table_id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.my_igw.id
}

resource "aws_security_group" "my_sg" {
    name = "${var.project}-sg"
    description = "allow http and ssh"
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

resource "aws_eks_cluster" "my_cluster"{
    name = "terraform-cluster"
    role_arn = aws_iam_role.eks_role.arn
    vpc_config {
    subnet_ids = [
      aws_subnet.private_subnet.id,
      aws_subnet.public_subnet.id
    ]
  }

  depends_on = [aws_iam_role_policy_attachment.example-AmazonEKSClusterPolicy]
}




