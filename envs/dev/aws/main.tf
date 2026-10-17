terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Auth comes from the environment: the AWS service connection in the pipeline (OIDC role),
# or your AWS profile locally.
provider "aws" {
  region = var.aws_region
}

module "aws" {
  source = "../../../modules/aws"

  environment             = "dev"
  instance_type           = var.instance_type
  asg_min_size            = var.asg_min_size
  asg_desired_capacity    = var.asg_desired_capacity
  asg_max_size            = var.asg_max_size
  use_golden_ami          = var.use_golden_ami
  alb_deletion_protection = var.alb_deletion_protection
  domain_name             = var.domain_name
  hosted_zone_name        = var.hosted_zone_name
}
