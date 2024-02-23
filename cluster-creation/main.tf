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
     map_public_ip_on_launch = false
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

#internet gateway
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    env = var.env
    Name = "${var.project}-igw"
  }
}

#route table
resource "aws_route" "igw_route" {
  route_table_id            = aws_vpc.my_vpc.default_route_table_id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.my_igw.id
}

#security group
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

#node role
resource "aws_iam_role" "noderole" {
  name = "node-role"
    assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

#attaching role policy and nodes
resource "aws_iam_role_policy_attachment" "my-node-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.noderole.name
}

resource "aws_iam_role_policy_attachment" "my-node-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.noderole.name
}

resource "aws_iam_role_policy_attachment" "my-node-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.noderole.name
}



#creating nodes
resource "aws_eks_node_group" "my-node" {
  cluster_name = aws_eks_cluster.my_cluster.name
  node_group_name = "new-node"
  node_role_arn = aws_iam_role.noderole.arn
  subnet_ids = [
    aws_subnet.private_subnet.id
  ]
  capacity_type = "ON_DEMAND"
  instance_types = ["t3.micro"]
  scaling_config {
    desired_size = 2
    min_size = 1
    max_size = 4
  }
  update_config {
    max_unavailable = 1
  }
  depends_on = [ 
    aws_iam_role_policy_attachment.my-node-AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.my-node-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.my-node-AmazonEKS_CNI_Policy
  ]
}

resource "aws_eip" "nat_gateway_eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "my_nat_gateway" {
  allocation_id = aws_eip.nat_gateway_eip.id
  subnet_id     = aws_subnet.public_subnet.id

  depends_on = [aws_eip.nat_gateway_eip]
}

# route table 
# data "aws_route_table" "private_subnet" {
#   subnet_id = aws_subnet.private_subnet.id
# }


# data "aws_route_table" "main" {
#   vpc_id = aws_vpc.my_vpc.id
# }

# Route Table for Private Subnet association
resource "aws_route_table_association" "private_subnet_association" {
  subnet_id      = aws_subnet.private_subnet.id
  # route_table_id = data.aws_route_table.private_subnet.id
  route_table_id = aws_route_table.my_route_table.id
  
}


# Creating NAT Gateway route for private subnet
/*
resource "aws_route" "nat_gateway_route" {
  route_table_id   = data.aws_route_table.private_subnet.id
  # route_table_id   = aws_vpc.my_vpc.default_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id   = aws_nat_gateway.my_nat_gateway.id
  depends_on       = [aws_nat_gateway.my_nat_gateway]
}

*/


resource "aws_route_table" "my_route_table" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "private-route-table"
  }
}

resource "aws_route" "nat_gateway_route" {
  # route_table_id   = data.aws_route_table.private_subnet.id
  # route_table_id   = aws_vpc.my_vpc.default_route_table_id

  route_table_id = aws_route_table.my_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id   = aws_nat_gateway.my_nat_gateway.id
  depends_on       = [aws_nat_gateway.my_nat_gateway]
}

/*

resource "aws_eip" "nat_gateway_eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "my_nat_gateway" {
  allocation_id = aws_eip.nat_gateway_eip.id
  subnet_id     = aws_subnet.public_subnet.id

  depends_on = [aws_eip.nat_gateway_eip]
}

data "aws_route_table" "private_subnet" {
  subnet_id = aws_subnet.private_subnet.id
}

# Route Table for Private Subnet
resource "aws_route_table_association" "private_subnet_association" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = 
}

# Creating NAT Gateway route for private subnet
resource "aws_route" "nat_gateway_route" {
  route_table_id   = data.aws_route_table.private_subnet.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id   = aws_nat_gateway.my_nat_gateway.id
  depends_on       = [aws_nat_gateway.my_nat_gateway]
}


*/

