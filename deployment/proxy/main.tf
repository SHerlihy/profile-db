terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
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

  vpc_security_group_ids = [var.redis_sg_id]

  key_name = aws_key_pair.profile_proxy.key_name
}

output "ec2_ip" {
  value = aws_instance.redis-ec2.public_ip
}

