output "lb_dns_name" {
  value       = aws_lb.ecs_lb.dns_name
  description = "The DNS name for the application load balancer"
}
