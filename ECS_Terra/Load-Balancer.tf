resource "aws_lb" "HelloLB" {
  name               = "HelloLB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.HelloSG.id]
  subnets            = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]

  tags = {
    Name = "LB"
  }
}

resource "aws_alb_listener" "Listener" {
  load_balancer_arn = aws_lb.HelloLB.id
  port              = "3000"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.HelloTG.id
    type             = "forward"
  }
}