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



resource "aws_eip" "nat_ip" {
  vpc = true
  tags = {
    "Name" = "NAT-GW-EIP"
  }
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_ip.id
  subnet_id     = aws_subnet.public_subnet[0].id
  tags = {
    "Name" = "NAT-GW-SUBNET"
  }
}

resource "aws_route_table" "nat_rt" {
  vpc_id = aws_vpc.main_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = {
    "Name" = "NAT-GW-RT"
  }
}

resource "aws_route_table_association" "nat_rta" {
  count          = length(var.az)
  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.nat_rt.id
}

