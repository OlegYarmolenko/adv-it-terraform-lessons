provider "aws" {
  region = "us-east-1"
}

data "aws_ssm_parameter" "linuxAmi" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

resource "aws_instance" "my_Ubuntu" {

  ami           = data.aws_ssm_parameter.linuxAmi.value
  instance_type = "t2.micro"

}
