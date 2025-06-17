
resource "aws_security_group" "ecs_service" {
  name        = "ecs-service-sg"
  description = "Allow inbound from ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = var.security_group_ids
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecs_task_definition" "task" {
  family                   = "slack-bot-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = var.task_exec_role_arn

  container_definitions = jsonencode([
    {
      name      = "slackbot",
      image     = var.container_image,
      portMappings = [{
        containerPort = var.container_port,
        protocol      = "tcp"
      }],
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = var.log_group_name,
          awslogs-region        = var.aws_region,
          awslogs-stream-prefix = "slackbot"
        }
      },
      environment = [{
        name  = "SLACK_BOT_TOKEN",
        value = "9homMwSn32sDTcchC4uQR65K"
      }]
    }
  ])
}

resource "aws_ecs_service" "main" {
  name            = "slack-bot-service"
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = var.subnet_ids
    security_groups = [aws_security_group.ecs_service.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = var.alb_target_group_arn
    container_name   = "slackbot"
    container_port   = var.container_port
  }

  depends_on = [aws_ecs_task_definition.task]
}
