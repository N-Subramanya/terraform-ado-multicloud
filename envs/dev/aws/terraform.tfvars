# dev: one small instance, stock Amazon Linux 2023 + user data
aws_region           = "us-east-1"
instance_type        = "t3.micro"
asg_min_size         = 1
asg_desired_capacity = 1
asg_max_size         = 2
use_golden_ami       = false
