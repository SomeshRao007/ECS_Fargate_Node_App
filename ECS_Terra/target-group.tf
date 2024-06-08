resource "aws_lb_target_group" "HelloTG" {
  name        = "HelloTG"
  port        = "3000"
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.hellovpc.id

  tags = {
    Name = "TG"
  }
}