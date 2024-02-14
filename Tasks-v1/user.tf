# 1. created IAM user in AWS using terraform 



provider "aws"{
    region = "eu-north-1"
}

resource "aws_iam_user" "user-name" {
    name = var.user-name
    tags = {
        env = var.env
    }
}



# 2. created s3 bucket in AWS using terraform 


resource "aws_s3_bucket" "my-bucket" {
    bucket = var.bucket-name
    tags = {
        Name = "s3-bucket"
        env = var.bucket-env
    }
}



# 3. create policy to access the bucket

resource "aws_iam_policy" "bucket_access_policy" {
    name = var.policy-name
    description = "Policy for accessing S3 bucket"
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:*"
            ],
            "Resource": [
                "${aws_s3_bucket.my-bucket.arn}/*"
            ]
        }
    ]
}
EOF
}

# 4. attach s3 policy to specific user

resource "aws_iam_user_policy_attachment" "attach-policy" {
    user       = aws_iam_user.user-name.name
    policy_arn = aws_iam_policy.bucket_access_policy.arn
}
