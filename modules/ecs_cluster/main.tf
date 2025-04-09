
resource "aws_ecs_cluster" "main" {
  name = "slack-bot-cluster"
}

output "cluster_id" {
  value = aws_ecs_cluster.main.id
}
