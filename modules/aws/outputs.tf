output "vpc_id" {
  description = "VPC ID."
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs (ALB, NAT)."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private subnet IDs (web instances)."
  value       = aws_subnet.private[*].id
}

output "alb_dns_name" {
  description = "Public DNS name of the ALB."
  value       = aws_lb.this.dns_name
}

output "app_url" {
  description = "URL of the web app."
  value       = local.use_https ? "https://${var.domain_name}" : "http://${aws_lb.this.dns_name}"
}

output "ami_id" {
  description = "AMI used by the web tier."
  value       = local.ami_id
}
