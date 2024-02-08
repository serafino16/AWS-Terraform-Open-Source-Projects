output "ec2" {
  value       = aws_instance.ec2.id
}
output "topic" {
  value       = aws_sns_topic.topic.id
}
output "lambda" {
  value       = aws_lambda_function.lambda.id
}
output "rule" {
  value       = aws_cloudwatch_event_rule.event.id
}			