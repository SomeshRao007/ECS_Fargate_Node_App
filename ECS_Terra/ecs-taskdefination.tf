resource "aws_ecs_task_definition" "HelloTD" {
  family                   = "nginx"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.iam-role.arn
  network_mode             = "awsvpc"
  cpu                      = 1024
  memory                   = 2048
  container_definitions = jsonencode([
    {
      name      = "main-container"
      image     = "469563970583.dkr.ecr.ap-south-1.amazonaws.com/somesh007"
      cpu       = 1024
      memory    = 2048
      essential = true
      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
        }
      ]
    }
  ])
}


data "aws_ecs_task_definition" "HelloTD" {
  task_definition = aws_ecs_task_definition.HelloTD.family
}
