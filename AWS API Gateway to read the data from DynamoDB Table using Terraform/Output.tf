output "table_arn1" {
    value = aws_dynamodb_table.whizdbtable.arn
    description = "DynamoDB Table created successfully"
}
output "lambda_arn" {
  value = aws_lambda_function.lambda.arn
  description = "Lambda Function crerated successfully"
}
output "api_arn" {
  value = aws_api_gateway_rest_api.restapi.arn
  description = "API gateway created successfully"
}