provider "AWS" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region = "${var.region}"
}
### Creating security groups for ALB and EC2 instances ###
resource "aws_security_group" "ALB-SG" {
  name = "web-server-SG"
  description = "Allowing HTTP connection"
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
    
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [ "0.0.0.0/0" ]

  }
}
####  Creating 2 EC2 instances  ###

resource "aws_instance" "web-server" {

    ami             = "ami-01cc34ab2709337aa"
    instance_type   = "t2.micro"
    count           = 2
    key_name        = "whizlabs-key"
    security_groups = ["${aws_security_group.web-server.name}"]
    user_data = <<-EOF
       #!/bin/bash
       sudo su
        yum update -y
        yum install httpd -y
        systemctl start httpd
        systemctl enable httpd
        echo "<html><h1> Welcome to Whizlabs. Happy Learning from $(hostname -f)...</p> </h1></html>" >> /var/www/html/index.html
        EOF
    tags = {
        Name = "instance-${count.index}"
    }
}
##### VPC and Subnets ####

data "aws_vpc" "default" {
  default = true
}
data "aws_subnet" "Subnet1" {
  vpc_id = data.aws_vpc.default.id
  availability_zone = "us-east-1"
}
data "aws_subnet" "Subnet2" {
  vpc_id = data.aws_vpc.default
  availability_zone = "us-east-1b"
}		
#### Creating Target Group ###

resource "aws_lb_target_group" "TG" {
    health_check {
      interval = 10
      path = "/"
      protocol = "HTTP"
      timeout = 5
      healthy_threshold = 5
      unhealthy_threshold = 2

    }
    name = "Load-Balancer-TG"
    port = 80
    protocol = "HTTP"
    target_type = "instance"
    vpc_id = data.aws_vpc.default.id
  
}
#### Creating Application Load Balancer ####
resource "aws_lb" "application-lb" {
name = "AWS-Load-Balancer"
internal = false
ip_address_type = "ipv4"
load_balancer_type = "appliaction"
security_groups = [aws_security_group.ALB-SG.id]
subnets = [ data.aws_subnet.Subnet1.id ,
 data.aws_subnet.Subnet2 ]
 tags = {
    Name = "Amazon-ALB"
 }
  
}
#### Creating Listener ###
resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.application-lb.arn
  port = 80
  protocol = "HTTP"
  default_action {
    target_group_arn = aws_lb_target_group.TG.arn
    type = "forward"
  }


}
#### Attaching target group to load balancer ###
resource "aws_lb_target_group_attachment" "EC2-Attachment" {
  count = length(aws_instance.web-server)
  target_group_arn = aws_lb_target_group.TG.arn
  target_id = aws_instance.web-server[count.index].id
  
}