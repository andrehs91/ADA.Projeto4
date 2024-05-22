resource "aws_lb_target_group" "consumer_tg" {
  name        = "${var.project_name}-${terraform.workspace}-consumer-tg"
  port        = 8001
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.ecs_vpc.id
}

resource "aws_ecs_task_definition" "consumer" {
  family                   = "consumer"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "consumer"
      image     = "andrehs/ada.consumer:1"
      essential = true
      environment = [
        {
          name  = "CONNECTIONSTRINGS_REDIS",
          value = "redis"
        },
        {
          name  = "RABBITMQ_HOSTNAME",
          value = "rabbitmq"
        },
        {
          name  = "RABBITMQ_USERNAME",
          value = "guest"
        },
        {
          name  = "RABBITMQ_PASSWORD",
          value = "guest"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/${var.project_name}-${terraform.workspace}-consumer"
          awslogs-region        = "${var.aws_region}"
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "consumer_service" {
  name            = "${var.project_name}-${terraform.workspace}-consumer"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.consumer.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [for subnet in aws_subnet.ecs_subnet : subnet.id]
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  # service_registries {
  #   registry_arn = aws_service_discovery_service.example.arn
  # }
}

resource "aws_cloudwatch_log_group" "consumer-lg" {
  name              = "/ecs/${var.project_name}-${terraform.workspace}-consumer"
  retention_in_days = 1

  tags = {
    Environment = terraform.workspace
    Application = "consumer"
  }
}
