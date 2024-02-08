provider "aws" {
  region     = "${var.region}"
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
}
###################### Default VPC and Subnets

data "aws_vpc" "vpc" {
  default = true
}

data "aws_subnet" "subnet1" {
  vpc_id            = data.aws_vpc.vpc.id
  availability_zone = "us-east-1a"
}

# Creating Security Group
resource "aws_security_group" "whiz_sg" {
  name        = "Whiz_SG"
  description = "Security Group For VPC Endpoint"
  vpc_id      = data.aws_vpc.vpc.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
# Creating VPC Endpoint
resource "aws_vpc_endpoint" "vpcendpoint" {
  vpc_id             = data.aws_vpc.vpc.id
  subnet_ids         = [data.aws_subnet.subnet1.id]
  service_name       = "com.amazonaws.us-east-1.execute-api"
  vpc_endpoint_type = "Interface"
  security_group_ids = [aws_security_group.whiz_sg.id,]
  ip_address_type    = "ipv4"
}
# Creating DynamoDB Table
resource "aws_dynamodb_table" "whizdbtable" {
  name           = "whizdbtable"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "Id"
  attribute {
    name = "Id"
    type = "S" 
  }
}
# Adding Items to DynamoDB Table
resource "aws_dynamodb_table_item" "item1" {
  table_name = aws_dynamodb_table.whizdbtable.name
  hash_key   = aws_dynamodb_table.whizdbtable.hash_key
  item = <<ITEM
{
  "Id": {"S": "13"},
  "Firstname": {"S": "Arun"},
  "LastName": {"S": "Nanda"},
  "Age": {"S": "23"}
}
ITEM
}
resource "aws_dynamodb_table_item" "item2" {
  table_name = aws_dynamodb_table.whizdbtable.name
  hash_key   = aws_dynamodb_table.whizdbtable.hash_key
  item = <<ITEM
{
  "Id": {"S": "14"},
  "Firstname": {"S": "Vishakha"},
  "LastName": {"S": "Sharma"},
  "Age": {"S": "22"}
}
ITEM
}
resource "aws_dynamodb_table_item" "item3" {
  table_name = aws_dynamodb_table.whizdbtable.name
  hash_key   = aws_dynamodb_table.whizdbtable.hash_key
  item = <<ITEM
{
  "Id": {"S": "15"},
  "Firstname": {"S": "Chandra"},
  "LastName": {"S": "Prakash"},
  "Age": {"S": "32"}
}
ITEM
}

# Create Lambda Function
resource "aws_lambda_function" "lambda" {
  filename      = "lambda_function.zip"
  function_name = "lambda_function"
  role          = "arn:aws:iam::461815519783:role/lambda_roleqwedf"
  handler       = "lambda_function.lambda_handler"
  runtime = "python3.9"
  source_code_hash = filebase64sha256("lambda_function.zip")    
}


# Creating Rest API Gateway
resource "aws_api_gateway_rest_api" "restapi" {
    name        = "WhizlabAPI"
    description = "This is my API for demonstration purposes"
    endpoint_configuration {
        types            = ["PRIVATE"]
        vpc_endpoint_ids = [aws_vpc_endpoint.vpcendpoint.id]
    }
}

# Creating Resource
resource "aws_api_gateway_resource" "whizresource" {
    parent_id   = aws_api_gateway_rest_api.restapi.root_resource_id
    path_part   = "list"
    rest_api_id = aws_api_gateway_rest_api.restapi.id          
}
# Create Method for resource
resource "aws_api_gateway_method" "method" {
    rest_api_id   = aws_api_gateway_rest_api.restapi.id
    resource_id   = aws_api_gateway_resource.whizresource.id
    http_method   = "GET"
    authorization = "NONE"          
}
# Intergrate lambda Function with Method
resource "aws_api_gateway_integration" "LambdaIntegration1" {
    rest_api_id          = aws_api_gateway_rest_api.restapi.id
    resource_id          = aws_api_gateway_resource.whizresource.id
    http_method          = aws_api_gateway_method.method.http_method
    integration_http_method     = "POST"
    type                 = "AWS_PROXY"
    uri = aws_lambda_function.lambda.invoke_arn
}

# Add Lambda Permissons for API Gateway
resource "aws_lambda_permission" "allow_api" {
  statement_id  = "AllowAPIgatewayInvokation"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "apigateway.amazonaws.com"
} 

