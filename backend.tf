terraform {
  backend "s3" {
    key            = "project/cron2_backend.tfstate"
    bucket         = "newproject-terraform-backend-files"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "project_lambda_cron_2"
  }
}