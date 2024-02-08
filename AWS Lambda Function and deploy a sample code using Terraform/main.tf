
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
############ Creating an S3 source Bucket ############
resource "aws_s3_bucket" "sourcebucket" {
  bucket = "sourcebucket-${random_string.random.result}"
  force_destroy = true
}

############ Creating an S3 destination Bucket ############
resource "aws_s3_bucket" "destinationbucket" {
  bucket = "destinationbucket-${random_string.random.result}"
  force_destroy = true
}
resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}
resource "aws_iam_policy" "policy" {
  name        = "test_policy"

  policy = jsonencode({ 
   "Version":"2012-10-17",
   "Statement":[ 
      { 
         "Effect":"Allow",
         "Action":[ 
            "s3:GetObject"
         ],
         "Resource":[ 
            "${aws_s3_bucket.sourcebucket.arn}/*"
         ]
      },
      { 
         "Effect":"Allow",
         "Action":[ 
            "s3:PutObject"
         ],
         "Resource":[ 
            "${aws_s3_bucket.destinationbucket.arn}/*"
         ]
      }
   ]
})
}
resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.policy.arn
}

resource "aws_lambda_function" "test_lambda" {
  filename      = "index.zip"
  function_name = "Whizlabsfunc"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "index.handler"
  runtime = "nodejs16.x"
}
resource "aws_s3_bucket_notification" "aws-lambda-trigger" {
  bucket = aws_s3_bucket.sourcebucket.id
  lambda_function {
    lambda_function_arn = aws_lambda_function.test_lambda.arn
    events   = ["s3:ObjectCreated:*"]
  }
}
resource "aws_lambda_permission" "test" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.test_lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${aws_s3_bucket.sourcebucket.id}"
}


