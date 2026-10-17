variable "aws_region" {
  description = "AWS region."
  type        = string
}

variable "instance_type" {
  description = "Web tier instance type."
  type        = string
}

variable "asg_min_size" {
  description = "Minimum web instances."
  type        = number
}

variable "asg_desired_capacity" {
  description = "Desired web instances."
  type        = number
}

variable "asg_max_size" {
  description = "Maximum web instances."
  type        = number
}

variable "use_golden_ami" {
  description = "Use the Packer-built golden AMI."
  type        = bool
  default     = false
}

variable "alb_deletion_protection" {
  description = "Protect the ALB from deletion."
  type        = bool
  default     = false
}

variable "domain_name" {
  description = "Optional app FQDN (enables HTTPS)."
  type        = string
  default     = null
}

variable "hosted_zone_name" {
  description = "Route 53 zone for domain_name."
  type        = string
  default     = null
}
