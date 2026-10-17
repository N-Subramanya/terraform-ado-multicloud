# prod: two instances across AZs from the Packer golden AMI (build it first, see packer/)
aws_region              = "us-east-1"
instance_type           = "t3.small"
asg_min_size            = 2
asg_desired_capacity    = 2
asg_max_size            = 4
use_golden_ami          = true
alb_deletion_protection = true

# Optional HTTPS with your own domain (ACM certificate + Route 53 alias):
# domain_name      = "app.example.com"
# hosted_zone_name = "example.com"
