# Our default security group to access EC2 instances over SSH and HTTP.
resource "aws_security_group" "default" {
  name        = "awx-pg-terraform-sg"
  description = "Used in the terraform"
  vpc_id      = "vpc-063d697535c28d118"

  # SSH access from HH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["76.182.164.220/32"]
  }

  # SSH access from ALL
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access from the VPC
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.200.0.0/16"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # All traffic from awx-pg-terraform-sg-alb 
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    security_groups = ["${aws_security_group.alb.id}"]
  }
}

# alb security group.
resource "aws_security_group" "alb" {
  name        = "awx-pg-terraform-sg-alb"
  description = "Terraform load balancer security group"
  vpc_id      = "vpc-063d697535c28d118"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# AWS application load balancer.
resource "aws_alb" "alb" {
  name = "awx-pg-terraform-alb"

  subnets         = ["subnet-0be3e98afb5265df8", "subnet-00e42205515a5e5fe", "subnet-027e45368802e7872"]
  security_groups = ["${aws_security_group.alb.id}"]
}

# Target group alb 443.
resource "aws_alb_target_group" "group" {
  name     = "awx-pg-terraform-tg-alb"
  port     = 443
  protocol = "HTTPS"
  vpc_id   = "vpc-063d697535c28d118"
  stickiness {
    type = "lb_cookie"
  }
  # Alter the destination of the health check to be the login page.
  health_check {
    path = "/login"
    port = 443
  }
}

# alb listener http.
resource "aws_alb_listener" "listener_http" {
  load_balancer_arn = "${aws_alb.alb.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_alb_target_group.group.arn}"
    type             = "forward"
  }
}

# alb listener https.
resource "aws_alb_listener" "listener_https" {
  load_balancer_arn = "${aws_alb.alb.arn}"
  port              = "443"
  protocol          = "HTTPS"
#  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "arn:aws-us-gov:acm:us-gov-west-1:036436800059:certificate/e8fd61b1-111c-4e13-8913-295eb5ea9b38"
  default_action {
    target_group_arn = "${aws_alb_target_group.group.arn}"
    type             = "forward"
  }
}

# ec2 instance
resource "aws_instance" "awx-pg-terraform-ec2" {
  ami                         = "ami-04e2da4c5a3677244"
  associate_public_ip_address = "false"
  availability_zone           = "us-gov-west-1a"
  enclave_options {
    enabled = "false"
  }

  get_password_data                    = "false"
  hibernation                          = "false"
  instance_initiated_shutdown_behavior = "stop"
  instance_type                        = "t2.large"
  ipv6_address_count                   = "0"
  key_name                             = "alpha_key_pair"

  maintenance_options {
    auto_recovery = "default"
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = "1"
    http_tokens                 = "optional"
    instance_metadata_tags      = "disabled"
  }

  monitoring = "true"
#  private_ip = "10.100.0.181"

  root_block_device {
    delete_on_termination = "true"
    encrypted             = "true"
    kms_key_id            = "arn:aws-us-gov:kms:us-gov-west-1:036436800059:key/23051040-d05e-4080-99f6-bbd740bb1b14"
    volume_size           = "100"
    volume_type           = "gp2"
  }

  source_dest_check = "true"
  subnet_id         = "subnet-065a186548ac826cf"

  tags = {
    Environment = "PS"
    Name        = "awx-pg-terraform-ec2"
  }

  tags_all = {
    Environment = "PS"
    Name        = "awx-pg-terraform-ec2"
  }

  tenancy                = "default"
  vpc_security_group_ids = ["${aws_security_group.default.id}"]

}

# Register EC2 instance to Target Group
resource "aws_lb_target_group_attachment" "register" {
  target_group_arn = "${aws_alb_target_group.group.arn}"
  target_id        = "${aws_instance.awx-pg-terraform-ec2.id}"
  port             = 443
}
