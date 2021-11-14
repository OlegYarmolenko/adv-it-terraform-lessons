provider "aws" {
  region = "us-east-1"
}

data "aws_availability_zones" "available" {}
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_ssm_parameter" "my_webserver" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}


resource "aws_security_group" "my_webserver" {
  name        = "Webserver SG"
  description = "Allow TCP/80"

  dynamic "ingress" {
    for_each = ["80", "443"]
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_launch_configuration" "web" {
  // name            = "Webserver"
  name_prefix     = "WebServer-HA-ELB-"
  image_id        = data.aws_ssm_parameter.my_webserver.value
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.my_webserver.id]
  user_data       = file("user_data.sh")

  lifecycle {
    create_before_destroy = true
  }

}

resource "aws_autoscaling_group" "web" {
  name                 = "ASG-${aws_launch_configuration.web.name}"
  launch_configuration = aws_launch_configuration.web.name
  min_size             = 2
  max_size             = 2
  min_elb_capacity     = 2
  health_check_type    = "ELB"
  vpc_zone_identifier  = [aws_default_subnet.default_az1.id, aws_default_subnet.default_az2.id]
  load_balancers       = [aws_elb.web.name]


  dynamic "tag" {
    for_each = {
      Name   = "Webserver in ASG"
      Owner  = "Oleh Yarmolenko"
      TAGKEY = "TAGVALUE"
    }
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_elb" "web" {
  name               = "WebServer-HA-ELB"
  availability_zones = ["us-east-1a", "us-east-1b"]
  security_groups    = [aws_security_group.my_webserver.id]
  listener {
    lb_port           = 80
    lb_protocol       = "http"
    instance_port     = 80
    instance_protocol = "http"

  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 10
  }

  tags = {
    Name = "Webserver-HA-ELB"
  }

}

resource "aws_default_subnet" "default_az1" {
  availability_zone = "us-east-1a"
}
resource "aws_default_subnet" "default_az2" {
  availability_zone = "us-east-1b"
}
output "web_loadbalancer" {
  value = aws_elb.web.name
}
output "aws_availability_zones" {
  value = data.aws_availability_zones.available.names
}
