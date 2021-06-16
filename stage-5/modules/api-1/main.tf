resource "aws_security_group" "instance_sg" {
  vpc_id      = var.vpc_id
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

resource "aws_instance" "instance" {
  count                  = length(var.az)
  ami                    = "ami-01d25dbd8703c2aa9"
  instance_type          = "t2.micro"
  subnet_id              = var.private_subnets[count.index]
  availability_zone      = "us-east-1${var.az[count.index]}"
  key_name               = "test-pair-1"
  vpc_security_group_ids = [aws_security_group.instance_sg.id]
  user_data              = templatefile("${path.module}/change.tmpl", { ip = var.api_2_ip })



  tags = {
    "Name" = "INSTANCE-${count.index}"
  }
}

resource "aws_security_group" "lb_sg" {
  vpc_id      = var.vpc_id
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


resource "aws_elb" "elb" {
  name      = "my-elb"
  subnets   = [for i, v in var.public_subnets : v]
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
