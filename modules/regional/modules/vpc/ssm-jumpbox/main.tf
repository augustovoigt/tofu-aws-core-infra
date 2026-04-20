locals {
  architecture_from_ec2   = var.create_ssm_jumpbox ? data.aws_ec2_instance_type.ssm_jumpbox[0].supported_architectures[0] : ""
  architecture_for_ubuntu = local.architecture_from_ec2 == "x86_64" ? "amd64" : local.architecture_from_ec2
  security_group_ids = !var.create_ssm_jumpbox ? [] : (
    var.aws_service_base_security_group == null ? (
      [aws_security_group.ssm_jumpbox[0].id]) : (
  [var.aws_service_base_security_group.id, aws_security_group.ssm_jumpbox[0].id]))

  ami_id           = !var.create_ssm_jumpbox ? "" : (var.ami_id != "" ? var.ami_id : data.aws_ami.ubuntu[0].id)
  ubuntu_ami_owner = "099720109477"
}

data "aws_ec2_instance_type" "ssm_jumpbox" {
  count         = var.create_ssm_jumpbox ? 1 : 0
  instance_type = var.ssm_jumpbox_instance_type
}

data "aws_default_tags" "provider_tags" {
  count = var.create_ssm_jumpbox ? 1 : 0
}

data "aws_ami" "ubuntu" {
  count       = var.create_ssm_jumpbox ? 1 : 0
  most_recent = true
  owners      = [local.ubuntu_ami_owner]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-${local.architecture_for_ubuntu}-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_iam_role" "ssm" {
  count       = var.create_ssm_jumpbox ? 1 : 0
  name        = "${var.resource_prefix}-jumpbox"
  description = "The role for the ssm-jumpbox EC2 instance"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  count      = var.create_ssm_jumpbox ? 1 : 0
  role       = aws_iam_role.ssm[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm" {
  count = var.create_ssm_jumpbox ? 1 : 0
  name  = "${var.resource_prefix}-ssm"
  role  = aws_iam_role.ssm[0].name
}

data "aws_ebs_default_kms_key" "current" {
  count = var.create_ssm_jumpbox ? 1 : 0
}

resource "aws_security_group" "ssm_jumpbox" {
  count       = var.create_ssm_jumpbox ? 1 : 0
  name        = "${var.resource_prefix}-ssm-jumpbox"
  description = "${var.resource_prefix} SSM jumpbox Security Group"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.resource_prefix}-ssm-jumpbox"
  }

  lifecycle {
    ignore_changes = [description]
  }
}

resource "aws_vpc_security_group_egress_rule" "ssm_jumpbox" {
  count             = var.create_ssm_jumpbox ? 1 : 0
  security_group_id = aws_security_group.ssm_jumpbox[0].id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_launch_template" "ssm_jumpbox" {
  count         = var.create_ssm_jumpbox ? 1 : 0
  name          = "${var.resource_prefix}-ssm-jumpbox"
  image_id      = local.ami_id
  instance_type = var.ssm_jumpbox_instance_type

  vpc_security_group_ids = local.security_group_ids

  iam_instance_profile {
    name = aws_iam_instance_profile.ssm[0].name
  }

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      encrypted  = true
      kms_key_id = data.aws_ebs_default_kms_key.current[0].key_arn
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(data.aws_default_tags.provider_tags[0].tags, {
      Name = "${var.resource_prefix}-ssm-jumpbox"
    })
  }

  tag_specifications {
    resource_type = "volume"
    tags          = data.aws_default_tags.provider_tags[0].tags
  }

  tags = {
    Name = "${var.resource_prefix}-ssm-jumpbox"
  }
}

resource "aws_autoscaling_group" "ssm_jumpbox" {
  count               = var.create_ssm_jumpbox ? 1 : 0
  name                = "${var.resource_prefix}-ssm-jumpbox"
  min_size            = 0
  max_size            = 1
  desired_capacity    = var.ssm_jumpbox_desired_capacity
  vpc_zone_identifier = var.private_subnet_id

  launch_template {
    id      = aws_launch_template.ssm_jumpbox[0].id
    version = "$Latest"
  }

  lifecycle {
    ignore_changes = [desired_capacity]
  }
}