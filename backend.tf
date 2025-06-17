# terraform {
#   backend "s3" {
#     bucket         = "hrahmanslackbot2"
#     key            = "global/s3/terraform.tfstate"
#     region         = "eu-west-2"
#     dynamodb_table   = "terraform-lock"
#     encrypt        = true
#   }
# }
