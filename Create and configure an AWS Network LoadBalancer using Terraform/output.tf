output "ec2" {
  value       = aws_instance.ec2.id
}
output "loadbalancer" {
  value       = aws_lb.loadbalancer.arn
}			