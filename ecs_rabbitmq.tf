resource "aws_lb_target_group" "rabbitmq_internal_tg" {
  name        = "${var.project_name}-${terraform.workspace}-rabbitmq-i-tg"
  port        = 5672
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.ecs_vpc.id
}

resource "aws_lb_listener" "rabbitmq_internal" {
  load_balancer_arn = aws_lb.ecs_lb.arn
  port              = 5672
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.rabbitmq_internal_tg.arn
  }
}

resource "aws_lb_target_group" "rabbitmq_tg" {
  name        = "${var.project_name}-${terraform.workspace}-rabbitmq-tg"
  port        = 15672
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.ecs_vpc.id
}

resource "aws_lb_listener" "rabbitmq" {
  load_balancer_arn = aws_lb.ecs_lb.arn
  port              = 15672
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.rabbitmq_tg.arn
  }
}

resource "aws_ecs_task_definition" "rabbitmq" {
  family                   = "rabbitmq"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "rabbitmq"
      image     = "rabbitmq:3.13-management"
      essential = true
      portMappings = [
        {
          containerPort = 5672
          hostPort      = 5672
        },
        {
          containerPort = 15672
          hostPort      = 15672
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/${var.project_name}-${terraform.workspace}-rabbitmq"
          awslogs-region        = "${var.aws_region}"
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "rabbitmq_service" {
  name            = "${var.project_name}-${terraform.workspace}-rabbitmq"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.rabbitmq.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  load_balancer {
    target_group_arn = aws_lb_target_group.rabbitmq_internal_tg.arn
    container_name   = "rabbitmq"
    container_port   = 5672
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.rabbitmq_tg.arn
    container_name   = "rabbitmq"
    container_port   = 15672
  }

  network_configuration {
    subnets          = [for subnet in aws_subnet.ecs_subnet : subnet.id]
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  service_registries {
    registry_arn = aws_service_discovery_service.example.arn
  }

  depends_on = [
    aws_lb_listener.rabbitmq_internal,
    aws_lb_listener.rabbitmq
  ]
}

resource "aws_cloudwatch_log_group" "rabbitmq-lg" {
  name              = "/ecs/${var.project_name}-${terraform.workspace}-rabbitmq"
  retention_in_days = 1

  tags = {
    Environment = terraform.workspace
    Application = "rabbitmq"
  }
}
