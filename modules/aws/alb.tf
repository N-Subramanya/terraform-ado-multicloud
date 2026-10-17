resource "aws_security_group" "alb" {
  name        = "sg-alb-${local.name}"
  description = "Public ALB: HTTP/HTTPS from the internet"
  vpc_id      = aws_vpc.this.id
  tags        = local.tags
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  #checkov:skip=CKV_AWS_260:Public web entry point; port 80 only forwards (no domain) or redirects to HTTPS
  security_group_id = aws_security_group.alb.id
  description       = "HTTP from the internet (redirected to HTTPS when a domain is set)"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  count = local.use_https ? 1 : 0

  security_group_id = aws_security_group.alb.id
  description       = "HTTPS from the internet"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "alb_to_app" {
  security_group_id            = aws_security_group.alb.id
  description                  = "HTTP to the web instances"
  ip_protocol                  = "tcp"
  from_port                    = 80
  to_port                      = 80
  referenced_security_group_id = aws_security_group.app.id
}

resource "aws_lb" "this" {
  #checkov:skip=CKV_AWS_91:Access logs need a dedicated S3 bucket; on the roadmap
  #checkov:skip=CKV_AWS_150:Deletion protection is a variable, enabled in prod (envs/prod/aws/terraform.tfvars)
  #checkov:skip=CKV2_AWS_28:WAF adds cost; on the roadmap for prod
  name                       = "alb-${local.name}"
  load_balancer_type         = "application"
  internal                   = false
  security_groups            = [aws_security_group.alb.id]
  subnets                    = aws_subnet.public[*].id
  drop_invalid_header_fields = true
  enable_deletion_protection = var.alb_deletion_protection
  tags                       = local.tags
}

resource "aws_lb_target_group" "app" {
  #checkov:skip=CKV_AWS_378:TLS terminates at the ALB; targets are private and only reachable from the ALB security group
  name     = "tg-${local.name}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.this.id

  health_check {
    path                = "/"
    matcher             = "200"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 15
  }

  tags = local.tags
}

# HTTP: forward when there is no domain/certificate, otherwise redirect to HTTPS
resource "aws_lb_listener" "http" {
  #checkov:skip=CKV_AWS_2:Redirects to HTTPS whenever domain_name is set; plain HTTP only when no certificate exists
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = local.use_https ? "redirect" : "forward"
    target_group_arn = local.use_https ? null : aws_lb_target_group.app.arn

    dynamic "redirect" {
      for_each = local.use_https ? [1] : []
      content {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }
}

resource "aws_lb_listener" "https" {
  count = local.use_https ? 1 : 0

  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate_validation.this[0].certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}
