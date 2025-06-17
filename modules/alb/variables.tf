variable "vpc_id" {}
variable "subnets" {
  description = "List of public subnet IDs to attach to the ALB"
  type        = list(string)
}

variable "target_port" {
  description = "Port that the target group forwards to"
  type        = number
}
variable "certificate_arn" {
  description = "ARN of the ACM certificate to use for HTTPS"
  type        = string
}