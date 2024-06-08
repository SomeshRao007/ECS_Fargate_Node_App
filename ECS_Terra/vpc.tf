resource "aws_vpc" "hellovpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "Hello-node-VPC"
  }
}

resource "aws_subnet" "subnet1" {
  vpc_id                  = aws_vpc.hellovpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-south-1a"

  tags = {
    Name = "Hello-public-Subnet1"
  }
}


resource "aws_subnet" "subnet2" {
  vpc_id                  = aws_vpc.hellovpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-south-1b"

  tags = {
    Name = "Hello-public-Subnet2"
  }
}

resource "aws_internet_gateway" "HelloIG" {
  vpc_id = aws_vpc.hellovpc.id

  tags = {
    Name = "Internet-Gateway"
  }
}


resource "aws_route_table" "HelloRT" {
  vpc_id = aws_vpc.hellovpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.HelloIG.id
  }
}


resource "aws_route_table_association" "RTA1" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.HelloRT.id
}


resource "aws_route_table_association" "RTA2" {
  subnet_id      = aws_subnet.subnet2.id
  route_table_id = aws_route_table.HelloRT.id
}