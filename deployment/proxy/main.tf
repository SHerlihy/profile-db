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

#resource "terraform_data" "provision_server" {
#  connection {
#    type = "ssh"
#    port = "22"
#
#    host = aws_instance.redis-ec2.public_ip
#    user = "ec2-user"
#
#    private_key = file("./.ssh/id_rsa")
#
#    timeout = "2m"
#  }
#
#    #  provisioner "file" {
#    #    source      = "./redis-cli.sh"
#    #    destination = "/tmp/redis-cli.sh"
#    #  }
#    #
#    #  provisioner "remote-exec" {
#    #    inline = [
#    #      "chmod +x /tmp/redis-cli.sh",
#    #      "/tmp/redis-cli.sh",
#    #      # "nohup /home/ec2-user/redis-stable/src/redis-cli -u rediss://${var.user_name}:${var.user_pass}@${aws_instance.redis-ec2.public_ip}:6379/0 > /dev/nul 2>&1 &"
#    #    ]
#    #  }
#}

output "ec2_ip" {
  value = aws_instance.redis-ec2.public_ip
}

