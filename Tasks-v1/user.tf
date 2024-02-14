provider "aws"{
    region = "eu-north-1"
}

resource "aws_iam_user" "user-name" {
    name = var.user-name
    tags = {
        env = var.env
    }
}