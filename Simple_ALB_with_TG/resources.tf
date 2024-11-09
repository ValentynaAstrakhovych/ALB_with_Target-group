# Define two instances using count and the first two subnets
resource "aws_instance" "web_server" {
  count         = 2
  ami           = data.aws_ami.latest_ubuntu.id
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.web_server.id]
  subnet_id = element(data.aws_subnets.current_region.ids, count.index)
  user_data = file("user_data.sh")

  tags = {
    Name = "web-server-${count.index + 1}"
  }
}

# Resource to generate a unique name for the security group
resource "random_pet" "sg" {}

# Security group for the instances
resource "aws_security_group" "web_server" {
  name = "${random_pet.sg.id}-sg"

  # Creates ingress rules for TCP ports 22, 80, and 443
  dynamic "ingress" {
    for_each = ["22", "80", "443"]
    content {
      from_port = ingress.value
      to_port   = ingress.value
      protocol  = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  # Allow ICMP traffic (PING)
  ingress {
    from_port = -1
    to_port   = -1
    protocol  = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Rule to allow all outbound traffic
  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Security Group Allowed ICMP and ports: 22-80-443"
  }
}

# Create Application Load Balancer (ALB) to distribute incoming HTTP traffic across instances
resource "aws_lb" "web" {
  name               = "web-server-lb"
  load_balancer_type = "application"
  security_groups = [aws_security_group.web_server.id]
  subnets = [element(data.aws_subnets.current_region.ids, 0), element(data.aws_subnets.current_region.ids, 1)]
  internal           = false

  tags = {
    Name = "web_server-lb"
  }
}

# Create target group
resource "aws_lb_target_group" "web_servers" {
  name     = "web-server-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "web-server-target-group"
  }
}

# Attach instances to the target group
resource "aws_lb_target_group_attachment" "web_servers" {
  count = length(aws_instance.web_server)
  target_group_arn = aws_lb_target_group.web_servers.arn
  target_id        = aws_instance.web_server[count.index].id
  port             = 80
}

# Create a listener for the ALB
resource "aws_lb_listener" "web" {
  load_balancer_arn = aws_lb.web.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_servers.arn
  }
}