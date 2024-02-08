provider "aws" {
    region     = "${var.region}"    
    access_key = "${var.access_key}"
    secret_key = "${var.secret_key}"
}
################## Creating an EKS Cluster ##################
resource "aws_eks_cluster" "cluster" {
  name     = "whiz"
  role_arn = "arn:aws:ec2:us-east-1:123456789012:instance/i-1234567890abcdef0"

  vpc_config {
    subnet_ids = ["SUBNET-e1150eac", "SUBNET-b43f6beb"]
  }
}
