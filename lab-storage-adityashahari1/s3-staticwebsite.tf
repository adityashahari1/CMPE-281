resource "aws_s3_bucket_website_configuration" "website-config" {
   # TODO: Look up aws_s3_bucket_website_configuration resource in 
   # terraform and fill out this resource with the correct values

   bucket = aws_s3_bucket.portfolio_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "404.html"
  }
}

output "endpoint" {
  value = aws_s3_bucket_website_configuration.website-config.website_endpoint
}