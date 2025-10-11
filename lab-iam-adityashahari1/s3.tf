data "aws_caller_identity" "current" {}

locals {
  my_first_name = "Aditya"
  my_last_name  = "Shahari"
  partners_s    = "Mohsen Minai"

  bucket_name = "tf-lab-${data.aws_caller_identity.current.account_id}"
  file_name   = "${local.my_first_name}_${local.my_last_name}.txt"
  file_body   = "My name is ${local.my_first_name} ${local.my_last_name}, my partner(s) are ${local.partners_s}."
}

resource "aws_s3_bucket" "lab" {
  bucket        = local.bucket_name
  force_destroy = true
  tags = {
    Name = "tf-lab"
  }
}

resource "aws_s3_object" "name_file" {
  bucket       = aws_s3_bucket.lab.bucket
  key          = "Aditya_Shahari.txt"
  content      = "My name is Aditya Shahari, my partner(s) are Mohsen Minai."
  content_type = "text/plain"

  tags = {
    Name = "Name File"
  }

  depends_on = [aws_s3_bucket.lab]
}


resource "aws_s3_bucket_policy" "allow_partner" {
  bucket = aws_s3_bucket.lab.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid      = "AllowPartnerRead",
        Effect   = "Allow",
        Principal = {
          AWS = "arn:aws:iam::654654340761:role/ec2-s3-access-role"
        },
        Action   = ["s3:ListBucket"],
        Resource = aws_s3_bucket.lab.arn
      },
      {
        Sid      = "AllowPartnerGetObject",
        Effect   = "Allow",
        Principal = {
          AWS = "arn:aws:iam::654654340761:role/ec2-s3-access-role" 
        },
        Action   = ["s3:GetObject"],
        Resource = "${aws_s3_bucket.lab.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket.lab]
}

output "bucket_name" {
  value = aws_s3_bucket.lab.bucket
}
