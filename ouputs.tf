output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnets" {
  value = module.vpc.public_subnets
}

output "private_subnets" {
  value = module.vpc.private_subnets
}

output "ecs_cluster_id" {
  value = module.ecs_cluster.cluster_id
}

output "execution_role_arn" {
  value = module.iam_roles.execution_role_arn
}

output "log_group_name" {
  value = module.cloudwatch_logs.log_group_name
}

output "alb_target_group_arn" {
  value = module.alb.target_group_arn
}

output "alb_security_group_id" {
  value = module.alb.ecs_sg_id
}

output "service_url" {
  value = "http://${module.alb.alb_dns_name}" # 👈 We can add this if you output DNS from the ALB module
}

output "alb_dns_name" {
  value = module.alb.dns_name
}