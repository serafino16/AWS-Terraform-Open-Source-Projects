provider "aws" {
    region     = "${var.region}"
    access_key = "${var.access_key}"
    secret_key = "${var.secret_key}"
}						
############ Creating a Random String ############
resource "random_string" "random" {
  length = 6
  special = false
  upper = false
}
############ Creating an S3 Bucket ############
resource "aws_s3_bucket" "bucket" {
  bucket = "whizbucket-${random_string.random.result}"
  force_destroy = true
}
############ Creating Bucket Public Access Block ############
resource "aws_s3_bucket_public_access_block" "public_access_block" {
  bucket = aws_s3_bucket.bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}			
# Upload an object
resource "aws_s3_object" "object" {
  bucket = aws_s3_bucket.bucket.id
  key    = "whizlabs_logo_58_32.png"
  source = "image/whizlabs_logo_58_32.png"
  etag = filemd5("image/whizlabs_logo_58_32.png")
}			

#Creating Bucket Policy
resource "aws_s3_bucket_policy" "public_read_access" {
  bucket = aws_s3_bucket.bucket.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": [
        "s3:list*",
        "s3:get*",
        "s3:putobject"
        ],
      "Resource": [
        "${aws_s3_bucket.bucket.arn}",
        "${aws_s3_bucket.bucket.arn}/*"
      ]
    }
  ]
}
EOF
}			


# Create Cloudfront distribution
locals {
  s3_origin_id = "myS3Origin"
}
resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = aws_s3_bucket.bucket.bucket_regional_domain_name
    origin_id   = local.s3_origin_id
  }
  enabled         = true
  is_ipv6_enabled = true
  comment         = "whiz-cloudfront"
  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 10
    max_ttl                = 20
  }
  price_class = "PriceClass_200"
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  viewer_certificate {
    cloudfront_default_certificate = true
  }
}			

