resource "aws_lb_target_group" "redis_internal_tg" {
  name        = "${var.project_name}-${terraform.workspace}-redis-i-tg"
  port        = 6379
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.ecs_vpc.id
}

resource "aws_lb_listener" "redis_internal" {
  load_balancer_arn = aws_lb.ecs_lb.arn
  port              = 6379
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.redis_internal_tg.arn
  }
}

resource "aws_lb_target_group" "redis_tg" {
  name        = "${var.project_name}-${terraform.workspace}-redis-tg"
  port        = 8001
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.ecs_vpc.id
}

resource "aws_lb_listener" "redis" {
  load_balancer_arn = aws_lb.ecs_lb.arn
  port              = 8001
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.redis_tg.arn
  }
}

resource "aws_ecs_task_definition" "redis" {
  family                   = "redis"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "redis"
      image     = "redis/redis-stack:latest"
      essential = true
      portMappings = [
        {
          containerPort = 6379
          hostPort      = 6379
        },
        {
          containerPort = 8001
          hostPort      = 8001
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/${var.project_name}-${terraform.workspace}-redis"
          awslogs-region        = "${var.aws_region}"
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "redis_service" {
  name            = "${var.project_name}-${terraform.workspace}-redis"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.redis.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  load_balancer {
    target_group_arn = aws_lb_target_group.redis_internal_tg.arn
    container_name   = "redis"
    container_port   = 6379
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.redis_tg.arn
    container_name   = "redis"
    container_port   = 8001
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
    aws_lb_listener.redis_internal,
    aws_lb_listener.redis
  ]
}

resource "aws_cloudwatch_log_group" "redis-lg" {
  name              = "/ecs/${var.project_name}-${terraform.workspace}-redis"
  retention_in_days = 1

  tags = {
    Environment = terraform.workspace
    Application = "redis"
  }
}
