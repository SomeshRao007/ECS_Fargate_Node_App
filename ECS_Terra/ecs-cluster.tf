resource "aws_ecs_cluster" "Hello-Node-app" {
  name = "Hello-Node-app"
  tags = {
    name = "hello-world-node-app"
  }
}
