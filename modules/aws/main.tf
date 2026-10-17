locals {
  name      = "${var.project}-${var.environment}"
  azs       = slice(data.aws_availability_zones.available.names, 0, length(var.public_subnet_cidrs))
  use_https = var.domain_name != null

  tags = merge(var.tags, {
    project     = var.project
    environment = var.environment
    managed_by  = "terraform"
  })
}

data "aws_availability_zones" "available" {
  #checkov:skip=CKV_AWS_394:AZs are only used to spread subnets; names are resolved once at create time
  state = "available"
}
