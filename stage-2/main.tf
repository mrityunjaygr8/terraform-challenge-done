terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.45.0"
    }
  }
  backend "s3" {
    bucket = "egt-tf-state"
    key    = "state"
    region = "us-east-1"
  }
}

provider "aws" {
  # Configuration options
  region = "us-east-1"
}

variable "az" {
  type    = list(string)
  default = ["a", "b", "c"]
}

resource "aws_vpc" "main" {
  cidr_block           = "172.16.0.0/16"
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true


  tags = {
    "Name" = "my-vpc"
  }
}

resource "aws_subnet" "subnet" {
  count      = length(var.az)
  cidr_block = "172.16.${count.index}.0/24"
  vpc_id     = aws_vpc.main.id
  depends_on = [
    aws_internet_gateway.ig
  ]
  availability_zone = "us-east-1${var.az[count.index]}"

  tags = {
    "Name" = "my-subnet"
  }
}

resource "aws_internet_gateway" "ig" {
  vpc_id = aws_vpc.main.id

  tags = {
    "Name" = "my-internet-gateway"
  }
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.main.id

  tags = {
    "Name" = "my-route-table"
  }
}

resource "aws_route" "route" {
  route_table_id         = aws_route_table.rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.ig.id

}

resource "aws_route_table_association" "rta" {
  subnet_id      = aws_subnet.subnet[count.index].id
  route_table_id = aws_route_table.rt.id
  count          = length(var.az)

}

resource "aws_security_group" "sec-grp" {
  name        = "My Sec Group"
  description = "My sec grp, allows all incoming on 3000, allow all out"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow all TCP on 3000"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Allow all tcp out"
    from_port   = 0
    to_port     = 0
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "Name" = "my-sec-grp"
  }
}

resource "aws_instance" "my-instance" {
  ami           = "ami-01d25dbd8703c2aa9"
  instance_type = "t2.micro"
  count         = length(var.az)

  private_ip        = "172.16.${count.index}.10"
  subnet_id         = aws_subnet.subnet[count.index].id
  availability_zone = "us-east-1${var.az[count.index]}"

  vpc_security_group_ids = [aws_security_group.sec-grp.id]
  key_name               = "test-pair-1"

  tags = {
    "Name" = "my-instance"
  }
}

resource "aws_eip" "my-eip" {
  vpc   = true
  count = length(var.az)

  instance                  = aws_instance.my-instance[count.index].id
  associate_with_private_ip = "172.16.${count.index}.10"
  depends_on = [
    aws_internet_gateway.ig
  ]

  tags = {
    "Name" = "my-eib"
  }
}

output "elastic-ip_0" {
  description = "The IP od th e EIP"
  value       = aws_eip.my-eip[0].public_ip
}

output "elastic-ip_1" {
  description = "The IP od th e EIP"
  value       = aws_eip.my-eip[1].public_ip
}
output "elastic-ip_2" {
  description = "The IP od th e EIP"
  value       = aws_eip.my-eip[2].public_ip
}
