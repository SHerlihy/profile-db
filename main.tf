terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "eu-west-2"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public_subnet_1" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.4.0/24"

  availability_zone = "eu-west-2a"
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.6.0/24"
  availability_zone = "eu-west-2b"
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "second_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "public_subnet_asso_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.second_rt.id
}

resource "aws_route_table_association" "public_subnet_asso_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.second_rt.id
}

resource "aws_security_group" "redis_sg" {
  name   = "redis_sg"
  vpc_id = aws_vpc.main.id
}

resource "aws_security_group_rule" "ingress_redis" {
  type              = "ingress"
  security_group_id = aws_security_group.redis_sg.id

  from_port   = 6379
  to_port     = 6379
  protocol    = "TCP"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "egress_all_ports" {
  type              = "egress"
  security_group_id = aws_security_group.redis_sg.id

  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group" "ec2_sg" {
  name   = "ec2_sg"
  vpc_id = aws_vpc.main.id
}

resource "aws_security_group_rule" "ingress_ec2" {
  type              = "ingress"
  security_group_id = aws_security_group.ec2_sg.id

  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "egress_ec2" {
  type              = "egress"
  security_group_id = aws_security_group.ec2_sg.id

  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_memorydb_user" "profileServiceRFG" {
  user_name     = var.user_name
  access_string = "on ~* &* +@all"

  authentication_mode {
    type      = "password"
    passwords = [var.user_pass]
  }
}

resource "aws_memorydb_acl" "profile" {
  user_names = [aws_memorydb_user.profileServiceRFG.id]
}

resource "aws_memorydb_subnet_group" "profile" {
  name       = "my-subnet-group"
  subnet_ids = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
}

resource "aws_memorydb_cluster" "profile" {
  acl_name           = aws_memorydb_acl.profile.id
  node_type          = "db.t4g.small"
  port               = 6379
  security_group_ids = [aws_security_group.redis_sg.id]
  subnet_group_name  = aws_memorydb_subnet_group.profile.id
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

resource "aws_key_pair" "redis-ec2-ssh-key" {
  key_name   = "redis-ec2-ssh-key"
  public_key = file("./.ssh/id_rsa.pub")
}

resource "aws_instance" "redis-ec2" {
  ami           = data.aws_ami.amazon-linux-2.id
  instance_type = "t2.micro"

  associate_public_ip_address = true

  subnet_id = aws_subnet.public_subnet_1.id

  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  key_name = aws_key_pair.redis-ec2-ssh-key.key_name
}

resource "terraform_data" "provision_server" {
  depends_on = [
    aws_memorydb_cluster.profile
  ]
  connection {
    type = "ssh"
    port = "22"

    host = aws_instance.redis-ec2.public_ip
    user = "ec2-user"

    private_key = file("./.ssh/id_rsa")

    timeout = "2m"
  }

  provisioner "remote-exec" {
    script = "./provision_scripts/redis-cli.sh"
  }
}

output "ec2_DNS" {
  value = aws_instance.redis-ec2.public_dns
}

output "cluster_DNS" {
  value = aws_memorydb_cluster.profile.cluster_endpoint[*].address
}
