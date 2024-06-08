terraform {
  backend "s3" {
    bucket  = "ecs-fragate-tf-file"
    region  = "ap-south-1"
    key     = "ecs-fargate-tf-file/node-hello-app/terraform.tfstate"
    encrypt = true
  }
  required_version = ">=0.13.0"
  required_providers {
    aws = {
      version = "~> 5.0"
      source  = "hashicorp/aws"
    }
  }
}