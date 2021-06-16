terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.45.0"
    }

    google = {
      source  = "hashicorp/google"
      version = "3.72.0"
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

provider "google" {
  # Configuration options
  project = "windy-city-316109"
  region  = "us-central1"
  zone    = "us-central1-c"
}

variable "az" {
  type    = list(string)
  default = ["a", "b", "c"]
}

resource "aws_vpc" "main_vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    "Name" = "MAIN-VPC"
  }
}

resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    "Name" = "MAIN-GW"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.main_vpc.id
  count             = length(var.az)
  cidr_block        = "10.0.1${count.index}.0/24"
  availability_zone = "us-east-1${var.az[count.index]}"

  tags = {
    "Name" = "PUBLIC-${count.index}"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.main_vpc.id
  count             = length(var.az)
  cidr_block        = "10.0.${count.index}.0/24"
  availability_zone = "us-east-1${var.az[count.index]}"

  tags = {
    "Name" = "PRIVATE-${count.index}"
  }
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }

  tags = {
    "Name" = "MAIN-ROUTE-TABLE"
  }
}

resource "aws_route_table_association" "rta" {
  count          = length(var.az)
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.rt.id
}

resource "aws_instance" "instance" {
  count                  = length(var.az)
  ami                    = "ami-01d25dbd8703c2aa9"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.private_subnet[count.index].id
  availability_zone      = "us-east-1${var.az[count.index]}"
  key_name               = "test-pair-1"
  vpc_security_group_ids = [aws_security_group.instance_sg.id]

  tags = {
    "Name" = "INSTANCE-${count.index}"
  }
}

resource "aws_security_group" "lb_sg" {
  vpc_id      = aws_vpc.main_vpc.id
  description = "Allows Load Balancer to listen on 80"

  ingress {
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
  }
  egress {
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "-1"
  }

  tags = {
    "Name" = "LB-SG"
  }
}

resource "aws_security_group" "instance_sg" {
  vpc_id      = aws_vpc.main_vpc.id
  description = "Allows access to API on instances"

  ingress {
    from_port   = 3000
    to_port     = 3000
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
  }
  egress {
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "-1"
  }

  tags = {
    "Name" = "INSTANCE-SG"
  }
}

resource "aws_elb" "elb" {
  name      = "my-elb"
  subnets   = [for i, v in var.az : aws_subnet.public_subnet[i].id]
  instances = [for i, v in var.az : aws_instance.instance[i].id]

  listener {
    instance_port     = 3000
    instance_protocol = "tcp"
    lb_port           = 80
    lb_protocol       = "tcp"
  }

  health_check {
    healthy_threshold   = 10
    unhealthy_threshold = 2
    timeout             = 5
    target              = "HTTP:3000/health"
    interval            = 30
  }

  security_groups = [aws_security_group.lb_sg.id]
  tags = {
    "Name" = "MAIN-LB"
  }
}

output "elb-dns" {
  description = "The DNS name of the ELB"
  value       = aws_elb.elb.dns_name
}

resource "google_compute_instance" "api2" {
  name         = "api-2"
  machine_type = "e2-micro"

  tags = ["api-2"]

  boot_disk {
    initialize_params {
      image = "projects/windy-city-316109/global/images/terraform-dojo-api-2"
    }
  }

  network_interface {
    network = "default"

    access_config {

    }
  }
}

output "api-2-IP" {
  description = "The IP of the API-2 machine"
  value       = google_compute_instance.api2.network_interface[0].access_config[0].nat_ip
}
