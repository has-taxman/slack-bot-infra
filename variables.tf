variable "cluster_id" {}
variable "task_exec_role_arn" {}
variable "container_image" {}          # 👈 Replace in tfvars or root main.tf
variable "log_group_name" {}
variable "alb_target_group_arn" {}
variable "subnet_ids" {}
variable "security_group_ids" {}
variable "vpc_id" {}
variable "container_port" {
  default = 8080                       # 👈 Match this to your bot's exposed port
}
variable "aws_region" {
  default = "eu-west-2"               # 👈 Set to your AWS region
}
