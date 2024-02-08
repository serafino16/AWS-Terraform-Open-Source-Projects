provider "AWS" {
  region = "${var.region}"
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
}
resource "random_string" "string" {
  length = 6
  special = false
  upper = false
}
resource "aws_s3_bucket" "bucket" {
  bucket = "Serafino ${random_string.string.result}"
  force_destroy = true
}
resource "aws_sns_topic" "topic" {
  name = "Serafino-s3-event-topic"
  policy = <<POLICY
{
    "Version":"2012-10-17",
    "Statement":[
        {
        "Effect": "Allow",
        "Principal": { "Service": "s3.amazonaws.com" },
        "Action": "SNS:Publish",
        "Resource": "arn:aws:sns:*:*:whiz-s3-event-notification",
        "Condition":{
            "ArnLike":{"aws:SourceArn":"${aws_s3_bucket.bucket.arn}"}
            }
        }
    ]
}
POLICY
}

resource "aws_sns_topic_subscription" "subscription" {
  topic_arn = aws_sns_topic.topic.arn
  protocol = "email"
  endpoint = "${var.endpoint}"
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.bucket.id
  topic {
    topic_arn = aws_sns_topic.topic.arn
    events = ["s3:ObjectCreated:*"]
  }
}
