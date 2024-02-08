provider "AWS" {
  region = var.region
  access_key = var.access_key
  secret_key = var.secret_key

}
##  Creating a random string ###
resource "random_string" "random" {
length = 6
special = false
upper = false
}
### Creating S3 Bucket##
resource "aws_s3_bucket" "Bucket" {
  bucket = "whizbucket-${random_string.random.result}"
  force_destroy = true
}
resource "aws_s3_bucket_website_configuration" "website" {
bucket = aws_s3_bucket.Bucket
index_document {
  suffix = "index.html"
}
error_document {
   key = "error.html"
}

}

resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.Bucket.id
  block_public_acls = false
  block_public_policy = false
  ignore_public_acls = false
  restrict_public_buckets = false
}
resource "aws_s3_object" "upload_object" {
  for_each      = fileset("html/", "*")
  bucket        = aws_s3_bucket.bucket.id
  key           = each.value
  source        = "html/${each.value}"
  etag          = filemd5("html/${each.value}")
  content_type  = "text/html"
}
resource "aws_s3_bucket_policy" "read_access_policy" {
  bucket = aws_s3_bucket.bucket.id
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": [
        "s3:GetObject"
      ],
      "Resource": [
        "${aws_s3_bucket.bucket.arn}",
        "${aws_s3_bucket.bucket.arn}/*"
      ]
    }
  ]
}
POLICY
}