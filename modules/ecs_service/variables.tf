
variable "cluster_id" {}
variable "task_exec_role_arn" {}
variable "container_image" {}
variable "log_group_name" {}
variable "alb_target_group_arn" {}
variable "subnet_ids" {}
variable "security_group_ids" {}
variable "vpc_id" {}
variable "container_port" {
  default = 3000
}
variable "aws_region" {
  default = "us-east-1"
}
