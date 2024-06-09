resource "aws_security_group" "HelloSG" {
  name        = "HelloSG"
  description = "Allow Port 3000"
  vpc_id      = aws_vpc.hellovpc.id

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SG"
  }
}
