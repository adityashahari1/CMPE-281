resource "aws_s3_bucket_acl" "example" {
  bucket = aws_s3_bucket.portfolio_bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "versioning_example" {
  bucket = aws_s3_bucket.portfolio_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_object_lock_configuration" "example" {
  bucket = aws_s3_bucket.portfolio_bucket.id

  rule {
    default_retention {
      mode = "GOVERNANCE"
      days = 5
    }
  }
}