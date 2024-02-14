# 1. created IAM user in AWS using terraform 

/*

provider "aws"{
    region = "eu-north-1"
}

resource "aws_iam_user" "user-name" {
    name = var.user-name
    tags = {
        env = var.env
    }
}

*/

# 2. created s3 bucket in AWS using terraform 

provider "aws" {
    region = "eu-north-1"
}

resource "aws_s3_bucket" "my-bucket" {
    bucket = var.bucket-name
    tags = {
        Name = "s3-bucket"
        env = var.bucket-env
    }
}