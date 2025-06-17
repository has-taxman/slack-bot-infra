provider "aws" {
  region = "eu-west-2"
}

# 1) DynamoDB table for Terraform state locking
resource "aws_dynamodb_table" "tf_lock" {
  name         = "terraform-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

# 2) VPC & subnets
module "vpc" {
  source = "./modules/vpc"
}

# 3) ECS Cluster
module "ecs_cluster" {
  source = "./modules/ecs_cluster"
  vpc_id = module.vpc.vpc_id
}

# 4) IAM roles for ECS
module "iam_roles" {
  source = "./modules/iam_roles"
}

# 5) CloudWatch Logs
module "cloudwatch_logs" {
  source = "./modules/cloudwatch_logs"
}

# ───────────────────────────────────────────
# 6) ACM certificate + DNS validation in Route 53
# ───────────────────────────────────────────

# 6a) Request a public cert for slack-bot.hasnatur-devops.com
resource "aws_acm_certificate" "slackbot" {
  domain_name       = "slack-bot.hasnatur-devops.com"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
  tags = {
    Name = "slack-bot-cert"
  }
}

# 6b) Lookup your Route 53 hosted zone
# Reusing for alias and DNS validation
data "aws_route53_zone" "primary" {
  name         = "hasnatur-devops.com."
  private_zone = false
}

# 6c) Create the CNAME records ACM gives you
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.slackbot.domain_validation_options :
    dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  zone_id = data.aws_route53_zone.primary.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 300
  records = [each.value.record]
}

# 6d) Wait for ACM to validate via DNS
resource "aws_acm_certificate_validation" "slackbot" {
  certificate_arn         = aws_acm_certificate.slackbot.arn
  validation_record_fqdns = [for r in aws_route53_record.cert_validation : r.fqdn]
}

# ───────────────────────────────────────────
# 7) ALB (with HTTPS via the new cert)
# ───────────────────────────────────────────
module "alb" {
  source          = "./modules/alb"
  vpc_id          = module.vpc.vpc_id
  subnets         = module.vpc.public_subnets
  target_port     = 8080
  certificate_arn = aws_acm_certificate.slackbot.arn
}

# ───────────────────────────────────────────
# 8) Route53 Alias Record pointing slack-bot.hasnatur-devops.com to ALB
# ───────────────────────────────────────────
resource "aws_route53_record" "slackbot_alias" {
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = "slack-bot"
  type    = "A"

  alias {
    name                   = module.alb.dns_name
    zone_id                = module.alb.zone_id
    evaluate_target_health = true
  }
}

# ───────────────────────────────────────────
# 9) ECS Service on Fargate behind the ALB
# ───────────────────────────────────────────
module "ecs_service" {
  source               = "./modules/ecs_service"
  vpc_id               = module.vpc.vpc_id
  cluster_id           = module.ecs_cluster.cluster_id
  task_exec_role_arn   = module.iam_roles.execution_role_arn
  container_image      = "717279702591.dkr.ecr.eu-west-2.amazonaws.com/slackbot:latest"
  log_group_name       = module.cloudwatch_logs.log_group_name
  alb_target_group_arn = module.alb.target_group_arn
  subnet_ids           = module.vpc.public_subnets
  security_group_ids   = [module.alb.ecs_sg_id]
  container_port       = 8080
  aws_region           = "eu-west-2"

  depends_on = [
    module.cloudwatch_logs,
    module.alb,
    aws_acm_certificate_validation.slackbot,
  ]
}
