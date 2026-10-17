output "app_url" {
  description = "URL of the web app."
  value       = module.aws.app_url
}

output "alb_dns_name" {
  description = "ALB DNS name."
  value       = module.aws.alb_dns_name
}

output "vpc_id" {
  description = "VPC ID."
  value       = module.aws.vpc_id
}
