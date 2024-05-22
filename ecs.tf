resource "aws_ecs_cluster" "ecs_cluster" {
  name = "${var.project_name}-${terraform.workspace}-cluster"

  tags = {
    Name = "${var.project_name}-${terraform.workspace}-cluster"
  }
}

resource "aws_lb" "ecs_lb" {
  name               = "${var.project_name}-${terraform.workspace}-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ecs_sg.id]
  subnets            = [for subnet in aws_subnet.ecs_subnet : subnet.id]

  tags = {
    Name = "${var.project_name}-${terraform.workspace}-lb"
  }
}
