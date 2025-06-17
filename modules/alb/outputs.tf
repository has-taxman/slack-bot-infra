
output "target_group_arn" {
  value = aws_lb_target_group.tg.arn
}

output "ecs_sg_id" {
  value = aws_security_group.alb_sg.id
}
output "alb_dns_name" {
  description = "The DNS name of the ALB"
  value       = aws_lb.main.dns_name
}
output "dns_name" {
  description = "The DNS name of the ALB"
  value       = aws_lb.main.dns_name
}

output "zone_id" {
  description = "The hosted zone ID of the ALB (for alias records)"
  value       = aws_lb.main.zone_id
}
