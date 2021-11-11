provider "aws" {
  region = "us-east-1"
}

data "aws_ssm_parameter" "my_webserver" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

resource "aws_instance" "my_webserver" {
  ami                    = data.aws_ssm_parameter.my_webserver.value
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.my_webserver.id]
  user_data              = file("user_data.sh")

  tags = {
    Name = "My webserver"
  }

}

resource "aws_security_group" "my_webserver" {
  name        = "Webserver SG"
  description = "Allow TCP/80"

  ingress {
    description = "Allow 80 from anyone IP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}













output "Webserver-Public-IP" {
  value = aws_instance.my_webserver.public_ip
}