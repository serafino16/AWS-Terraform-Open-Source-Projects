output "web_instance_ip" {
    value = aws_instance.web-server.public_ip 
}