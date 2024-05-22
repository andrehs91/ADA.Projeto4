resource "aws_lb_target_group" "producer_tg" {
  name        = "${var.project_name}-${terraform.workspace}-producer-tg"
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.ecs_vpc.id
}

resource "aws_lb_listener" "producer" {
  load_balancer_arn = aws_lb.ecs_lb.arn
  port              = 8080
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.producer_tg.arn
  }
}

resource "aws_ecs_task_definition" "producer" {
  family                   = "producer"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "producer"
      image     = "andrehs/ada.producer"
      essential = true
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
        },
        {
          containerPort = 8081
          hostPort      = 8081
        }
      ]
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
        },
        {
          name  = "MINIO_ENDPOINT",
          value = "${var.project_name}-${terraform.workspace}-minio"
        },
        {
          name  = "MINIO_ACCESSKEY",
          value = "MINIOACCESSKEY"
        },
        {
          name  = "MINIO_SECRETKEY",
          value = "MINIOSECRETKEY"
        },
        {
          name  = "MINIO_ISSECURE",
          value = "false"
        },
        {
          name  = "MINIO_PORT",
          value = "9000"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/${var.project_name}-${terraform.workspace}-producer"
          awslogs-region        = "${var.aws_region}"
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "producer_service" {
  name            = "${var.project_name}-${terraform.workspace}-producer"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.producer.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  load_balancer {
    target_group_arn = aws_lb_target_group.producer_tg.arn
    container_name   = "producer"
    container_port   = 8080
  }

  network_configuration {
    subnets          = [for subnet in aws_subnet.ecs_subnet : subnet.id]
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  depends_on = [
    aws_lb_listener.producer
  ]
}

resource "aws_cloudwatch_log_group" "producer-lg" {
  name              = "/ecs/${var.project_name}-${terraform.workspace}-producer"
  retention_in_days = 1

  tags = {
    Environment = terraform.workspace
    Application = "producer"
  }
}
