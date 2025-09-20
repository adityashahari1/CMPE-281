terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region  = "us-west-1"
}


# TODO: Define the values for these resources below. Look at README for links to read.

resource "aws_s3_bucket" "portfolio_bucket" {
  bucket = "cmpe281-adityabucket"

  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }

}

resource "aws_s3_object" "template_files" {
  for_each = fileset("${path.module}/s3-template", "**/*")

  bucket = aws_s3_bucket.portfolio_bucket.id  
  key    = each.value
  source = "${path.module}/s3-template/${each.value}"

  content_type = lookup(local.content_type_map,element(reverse(split(".", each.value)), 0),"application/octet-stream")
  
  # If the file changes, the MD5 changes, so Terraform updates the S3 object.
  etag = filemd5("${path.module}/s3-template/${each.value}")

}

locals {
  content_type_map = {
    html = "text/html"
    htm  = "text/html"
    css  = "text/css"
    js   = "application/javascript"
    mjs  = "text/javascript"

    json = "application/json"
    map  = "application/json"

    png  = "image/png"
    jpg  = "image/jpeg"
    jpeg = "image/jpeg"
    gif  = "image/gif"
    svg  = "image/svg+xml"
    webp = "image/webp"
    ico  = "image/x-icon"

    woff  = "font/woff"
    woff2 = "font/woff2"
    ttf   = "font/ttf"
    otf   = "font/otf"
    eot   = "application/vnd.ms-fontobject"
  }
}


