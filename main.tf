terraform {
  backend "s3" {
    bucket         = "your-tf-state-bucket-name"         # 👈 Your S3 bucket name for state
    key            = "slack-bot/terraform.tfstate"       # 👈 Path in the bucket
    region         = "us-east-1"                          # 👈 Adjust to your region
    dynamodb_table = "terraform-locks"                   # 👈 DynamoDB table for locking
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"  # 👈 Adjust to your preferred region
}

# VPC and Subnets
module "vpc" {
  source = "./modules/vpc"
}

# ECS Cluster
module "ecs_cluster" {
  source = "./modules/ecs_cluster"
  vpc_id = module.vpc.vpc_id
}

# IAM roles for ECS
module "iam_roles" {
  source = "./modules/iam_roles"
}

# CloudWatch Logs
module "cloudwatch_logs" {
  source = "./modules/cloudwatch_logs"
}

# ALB
module "alb" {
  source      = "./modules/alb"
  vpc_id      = module.vpc.vpc_id
  subnets     = module.vpc.public_subnets
  target_port = 3000  # 👈 Match your bot’s port
}

# ECS Service with Fargate
module "ecs_service" {
  source               = "./modules/ecs_service"
  cluster_id           = module.ecs_cluster.cluster_id
  task_exec_role_arn   = module.iam_roles.execution_role_arn
  container_image      = "your-ecr-or-dockerhub-image"  # 👈 Replace with your image URL
  log_group_name       = module.cloudwatch_logs.log_group_name
  alb_target_group_arn = module.alb.target_group_arn
  subnet_ids           = module.vpc.private_subnets
  security_group_ids   = [module.alb.ecs_sg_id]
  container_port       = 3000
}

