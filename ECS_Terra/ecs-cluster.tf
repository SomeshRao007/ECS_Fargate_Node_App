resource "aws_ecs_cluster" "HelloECS" {
  name = "Hello-Node-app"
  tags = {
    name = "hello-world-node-app"
  }
}