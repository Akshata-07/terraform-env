provider "aws"{
    region = "eu-north-1"
}
/*
resource "aws_iam_role" "eks_role" {
  name = "eks-cluster-role"
   assume_role_policy = <<POLICY
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Principal": {
                    "Service": [
                        "eks.amazonaws.com"
                    ]
                },
                "Action": "sts:AssumeRole"
            }
        ]
    }
    POLICY
}

resource "aws_iam_role_policy_attachment" "demo-AmazonEKSClusterPolicy" {
  role       = aws_iam_role.eks_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

*/


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




resource "aws_eks_cluster" "my_cluster"{
    name = "terraform-cluster"
    role_arn = aws_iam_role.eks_role.arn
    vpc_config {
    subnet_ids = [
      aws_subnet.private-eu-north-1a.id,
      aws_subnet.private-eu-north-1b.id,
      aws_subnet.public-eu-north-1a.id,
      aws_subnet.public-eu-north-1b.id
    ]
  }

  depends_on = [aws_iam_role_policy_attachment.example-AmazonEKSClusterPolicy]
}




