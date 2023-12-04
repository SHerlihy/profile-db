terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}
resource "aws_internet_gateway" "gw" {
  vpc_id = var.profile_db_vpc_id
}

resource "aws_route_table" "second_rt" {
  vpc_id = var.profile_db_vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "public_subnet_asso_1" {
  subnet_id      = var.redis_subnet_id
  route_table_id = aws_route_table.second_rt.id
}

resource "aws_security_group" "proxy_sg" {
  name   = "proxy_sg"
  vpc_id = var.profile_db_vpc_id
}

resource "aws_security_group_rule" "ingress_ec2" {
  type              = "ingress"
  security_group_id = aws_security_group.proxy_sg.id

  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "egress_ec2" {
  type              = "egress"
  security_group_id = aws_security_group.proxy_sg.id

  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}

data "aws_ami" "amazon-linux-2" {
  most_recent = true


  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }


  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

resource "aws_key_pair" "profile_proxy" {
  key_name   = "redis-ec2-ssh-key"
  public_key = file("./.ssh/id_rsa.pub")
}

resource "aws_instance" "redis-ec2" {
  ami           = data.aws_ami.amazon-linux-2.id
  instance_type = "t2.micro"

  associate_public_ip_address = true

  subnet_id = var.redis_subnet_id

  vpc_security_group_ids = [aws_security_group.proxy_sg.id]

  key_name = aws_key_pair.profile_proxy.key_name
}

output "ec2_ip" {
  value = aws_instance.redis-ec2.public_ip
}

