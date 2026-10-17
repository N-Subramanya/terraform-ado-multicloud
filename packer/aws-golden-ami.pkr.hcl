# Golden AMI for the AWS web tier: Amazon Linux 2023 + nginx, encrypted, IMDSv2-only.
# Build:  packer init . && packer build -var "region=us-east-1" .
# Terraform picks the newest AMI named "<ami_name_prefix>*" when use_golden_ami = true.

packer {
  required_plugins {
    amazon = {
      version = "~> 1.8"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "ami_name_prefix" {
  type    = string
  default = "multicloud-web-"
}

data "amazon-parameterstore" "al2023" {
  name   = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
  region = var.region
}

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

source "amazon-ebs" "web" {
  region        = var.region
  instance_type = var.instance_type
  source_ami    = data.amazon-parameterstore.al2023.value
  ssh_username  = "ec2-user"
  ami_name      = "${var.ami_name_prefix}${local.timestamp}"
  encrypt_boot  = true
  imds_support  = "v2.0"

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tags = {
    Name       = "${var.ami_name_prefix}${local.timestamp}"
    project    = "multicloud"
    built_by   = "packer"
    base_image = "al2023"
  }
}

build {
  sources = ["source.amazon-ebs.web"]

  provisioner "file" {
    source      = "${path.root}/files/index.html"
    destination = "/tmp/index.html"
  }

  provisioner "shell" {
    inline = [
      "sudo dnf -y update",
      "sudo dnf -y install nginx",
      "sudo mv /tmp/index.html /usr/share/nginx/html/index.html",
      "sudo systemctl enable nginx",
      "sudo dnf clean all",
    ]
  }
}
