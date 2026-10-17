variable "project" {
  description = "Short project name used in resource names."
  type        = string
  default     = "multicloud"
}

variable "environment" {
  description = "Environment name (dev, prod)."
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be dev or prod."
  }
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC."
  type        = string
  default     = "10.37.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Public subnets (ALB, NAT), one per AZ."
  type        = list(string)
  default     = ["10.37.1.0/24", "10.37.2.0/24", "10.37.3.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private subnets (web instances), one per AZ."
  type        = list(string)
  default     = ["10.37.20.0/24", "10.37.21.0/24"]
}

variable "enable_nat_gateway" {
  description = "Create a NAT gateway so private instances can reach the internet (package updates)."
  type        = bool
  default     = true
}

variable "instance_type" {
  description = "EC2 instance type for the web tier."
  type        = string
  default     = "t3.micro"
}

variable "asg_min_size" {
  description = "Minimum number of web instances."
  type        = number
  default     = 1
}

variable "asg_desired_capacity" {
  description = "Desired number of web instances."
  type        = number
  default     = 1
}

variable "asg_max_size" {
  description = "Maximum number of web instances."
  type        = number
  default     = 2
}

variable "use_golden_ami" {
  description = "Use the Packer-built golden AMI (true) or stock Amazon Linux 2023 + user data (false)."
  type        = bool
  default     = false
}

variable "golden_ami_name_prefix" {
  description = "Name prefix of the Packer-built AMI."
  type        = string
  default     = "multicloud-web-"
}

variable "domain_name" {
  description = "Optional FQDN for the app (e.g. app.example.com). Enables ACM + HTTPS + Route 53 record. null = HTTP on the ALB DNS name."
  type        = string
  default     = null
}

variable "hosted_zone_name" {
  description = "Route 53 public hosted zone that contains domain_name (e.g. example.com). Required when domain_name is set."
  type        = string
  default     = null
}

variable "alb_deletion_protection" {
  description = "Protect the ALB from deletion (recommended for prod)."
  type        = bool
  default     = false
}

variable "flow_log_retention_days" {
  description = "Retention of VPC flow logs in CloudWatch."
  type        = number
  default     = 365
}

variable "tags" {
  description = "Extra tags applied to every resource."
  type        = map(string)
  default     = {}
}
