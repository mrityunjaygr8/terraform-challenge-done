# terraform {
#   required_providers {
#     aws = {
#       source  = "hashicorp/aws"
#       version = "3.45.0"
#     }
#   }
#   backend "s3" {
#     bucket = "egt-tf-state"
#     key    = "state"
#     region = "us-east-1"
#   }
# }

# provider "aws" {
#   # Configuration options
#   region = "us-east-1"
# }

# variable "az" {
#   type    = list(string)
#   default = ["a", "b", "c"]
# }

# resource "aws_vpc" "main" {
#   cidr_block           = "172.16.0.0/16"
#   instance_tenancy     = "default"
#   enable_dns_hostnames = true
#   enable_dns_support   = true


#   tags = {
#     "Name" = "my-vpc"
#   }
# }

# resource "aws_subnet" "pub_subnet" {
#   count      = length(var.az)
#   cidr_block = "172.16.${count.index}.0/24"
#   vpc_id     = aws_vpc.main.id
#   depends_on = [
#     aws_internet_gateway.ig
#   ]
#   availability_zone = "us-east-1${var.az[count.index]}"

#   tags = {
#     "Name" = "my-public-subnet-${count.index}"
#   }
# }

# resource "aws_subnet" "pri_subnet" {
#   count             = length(var.az)
#   cidr_block        = "172.16.1${count.index}.0/24"
#   vpc_id            = aws_vpc.main.id
#   availability_zone = "us-east-1${var.az[count.index]}"

#   tags = {
#     "Name" = "my-private-subnet-${count.index}"
#   }
# }

# resource "aws_internet_gateway" "ig" {
#   vpc_id = aws_vpc.main.id

#   tags = {
#     "Name" = "my-internet-gateway"
#   }
# }

# resource "aws_route_table" "rt" {
#   vpc_id = aws_vpc.main.id

#   tags = {
#     "Name" = "my-route-table"
#   }
# }

# resource "aws_route" "route" {
#   route_table_id         = aws_route_table.rt.id
#   destination_cidr_block = "0.0.0.0/0"
#   gateway_id             = aws_internet_gateway.ig.id

# }

# resource "aws_route_table_association" "rta" {
#   subnet_id      = aws_subnet.pub_subnet[count.index].id
#   route_table_id = aws_route_table.rt.id
#   count          = length(var.az)

# }

# resource "aws_security_group" "lb-sg" {
#   description = "My sec grp, allows all incoming on 80, allow all out from/to LB"
#   vpc_id      = aws_vpc.main.id

#   ingress {
#     description = "Allow all TCP on 80"
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress {
#     description = "Allow all tcp out"
#     from_port   = 0
#     to_port     = 0
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     "Name" = "my-sec-grp"
#   }
# }

# resource "aws_security_group" "instance_sg" {
#   description = "Allows ingress on 3000 from LB, all egress"
#   vpc_id      = aws_vpc.main.id

#   ingress {
#     description = "Allow on tcp 3000 from LB"
#     from_port   = 3000
#     to_port     = 3000
#     protocol    = "tcp"
#     # security_groups = ["${aws_security_group.lb-sg.id}"]
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#   egress {
#     description = "Allow all tcp out"
#     from_port   = 0
#     to_port     = 0
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

# resource "aws_elb" "lb" {
#   # subnets         = flatten([for i, v in var.az : [for t in toset(["pub", "pri"]) : "aws_subnet.${t}_subnet[${i}].id"]])
#   # subnets = flatten([for t in toset(["pub_subnet", "pri_subnet"]) : [for i, v in var.az : aws_subnet.t["${i}"].id]])
#   # instances       = [aws_instance.ek-aur.id]
#   name            = "my-classic-lb"
#   subnets         = [for i, v in var.az : aws_subnet.pub_subnet[i].id]
#   instances       = [for i, k in var.az : aws_instance.my-instance[i].id]
#   security_groups = [aws_security_group.lb-sg.id]
#   # subnets         = [aws_subnet.pri_subnet[0].id, aws_subnet.pri_subnet[1].id, aws_subnet.pri_subnet[2].id, ]

#   # dynamic "subnets" {
#   #   for_each = toset(["pub_subnet", "pri_subnet"])
#   #   content = [for i, v in var.az: aws_subnet.]
#   # }

#   listener {
#     instance_port     = 3000
#     instance_protocol = "http"
#     lb_port           = 80
#     lb_protocol       = "http"
#   }

#   health_check {
#     healthy_threshold   = 2
#     unhealthy_threshold = 2
#     timeout             = 3
#     target              = "HTTP:3000/health"
#     interval            = 30
#   }
#   cross_zone_load_balancing   = true
#   idle_timeout                = 400
#   connection_draining         = true
#   connection_draining_timeout = 400
#   internal                    = true

#   tags = {
#     "Name" = "my-classic-lb"
#   }
# }


# resource "aws_instance" "my-instance" {
#   ami           = "ami-01d25dbd8703c2aa9"
#   instance_type = "t2.micro"
#   count         = length(var.az)

#   subnet_id         = aws_subnet.pub_subnet[count.index].id
#   availability_zone = "us-east-1${var.az[count.index]}"

#   vpc_security_group_ids = [aws_security_group.sec-grp.id]
#   key_name               = "test-pair-1"


#   tags = {
#     "Name" = "my-instance"
#   }
# }

# output "elb_dns_name" {
#   description = "The dns name of the classic EC2 LB"
#   value       = aws_elb.lb.dns_name
# }

# resource "aws_security_group" "sec-grp" {
#   name        = "My Sec Group"
#   description = "My sec grp, allows all incoming on 3000, allow all out"
#   vpc_id      = aws_vpc.main.id

#   ingress {
#     description = "Allow all TCP"
#     from_port   = 3000
#     to_port     = 3000
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   ingress {
#     description = "Allow ssh"
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#   egress {
#     description = "Allow all tcp out"
#     from_port   = 0
#     to_port     = 0
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     "Name" = "my-sec-grp"
#   }
# }

# resource "aws_instance" "ek-aur" {
#   ami                    = "ami-01d25dbd8703c2aa9"
#   instance_type          = "t2.micro"
#   subnet_id              = aws_subnet.pub_subnet[0].id
#   private_ip             = "172.16.0.10"
#   vpc_security_group_ids = [aws_security_group.sec-grp.id]
#   key_name               = "test-pair-1"
# }

# resource "aws_eip" "my-eip" {
#   vpc = true

#   instance                  = aws_instance.ek-aur.id
#   associate_with_private_ip = "172.16.0.10"
#   depends_on = [
#     aws_internet_gateway.ig
#   ]

#   tags = {
#     "Name" = "my-eib"
#   }
# }

# output "elastic-ip" {
#   description = "The IP od th e EIP"
#   value       = aws_eip.my-eip.public_ip
# }
