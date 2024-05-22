# resource "aws_lb_target_group" "minio_internal_tg" {
#   name        = "${var.project_name}-${terraform.workspace}-minio-i-tg"
#   port        = 9000
#   protocol    = "HTTP"
#   target_type = "ip"
#   vpc_id      = aws_vpc.ecs_vpc.id
# }

# resource "aws_lb_listener" "minio_internal" {
#   load_balancer_arn = aws_lb.ecs_lb.arn
#   port              = 9000
#   protocol          = "HTTP"

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.minio_internal_tg.arn
#   }
# }

# resource "aws_lb_target_group" "minio_tg" {
#   name        = "${var.project_name}-${terraform.workspace}-minio-tg"
#   port        = 9001
#   protocol    = "HTTP"
#   target_type = "ip"
#   vpc_id      = aws_vpc.ecs_vpc.id
# }

# resource "aws_lb_listener" "minio" {
#   load_balancer_arn = aws_lb.ecs_lb.arn
#   port              = 9001
#   protocol          = "HTTP"

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.minio_tg.arn
#   }
# }

# resource "aws_ecs_task_definition" "minio" {
#   family                   = "minio"
#   network_mode             = "awsvpc"
#   requires_compatibilities = ["FARGATE"]
#   cpu                      = "256"
#   memory                   = "512"
#   execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

#   container_definitions = jsonencode([
#     {
#       name      = "minio"
#       image     = "quay.io/minio/minio"
#       essential = true
#       portMappings = [
#         {
#           containerPort = 9000
#           hostPort      = 9000
#         },
#         {
#           containerPort = 9001
#           hostPort      = 9001
#         }
#       ]
#       logConfiguration = {
#         logDriver = "awslogs"
#         options = {
#           awslogs-group         = "/ecs/${var.project_name}-${terraform.workspace}-minio"
#           awslogs-region        = "${var.aws_region}"
#           awslogs-stream-prefix = "ecs"
#         }
#       }
#     }
#   ])
# }

# resource "aws_ecs_service" "minio_service" {
#   name            = "${var.project_name}-${terraform.workspace}-minio"
#   cluster         = aws_ecs_cluster.ecs_cluster.id
#   task_definition = aws_ecs_task_definition.minio.arn
#   desired_count   = 1
#   launch_type     = "FARGATE"

#   load_balancer {
#     target_group_arn = aws_lb_target_group.minio_internal_tg.arn
#     container_name   = "minio"
#     container_port   = 9000
#   }

#   load_balancer {
#     target_group_arn = aws_lb_target_group.minio_tg.arn
#     container_name   = "minio"
#     container_port   = 9001
#   }

#   network_configuration {
#     subnets          = [for subnet in aws_subnet.ecs_subnet : subnet.id]
#     security_groups  = [aws_security_group.ecs_sg.id]
#     assign_public_ip = true
#   }

#   service_registries {
#     registry_arn = aws_service_discovery_service.example.arn
#   }

#   depends_on = [
#     aws_lb_listener.minio
#   ]
# }

# resource "aws_cloudwatch_log_group" "minio-lg" {
#   name              = "/ecs/${var.project_name}-${terraform.workspace}-minio"
#   retention_in_days = 1

#   tags = {
#     Environment = terraform.workspace
#     Application = "minio"
#   }
# }
