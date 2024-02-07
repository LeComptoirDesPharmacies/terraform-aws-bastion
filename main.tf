resource "aws_kms_key" "key" {
  enable_key_rotation = var.kms_enable_key_rotation
  tags                = merge(var.tags)
}

resource "aws_kms_alias" "alias" {
  name          = "alias/${replace(var.bucket_name, ".", "_")}"
  target_key_id = aws_kms_key.key.arn
}

data "aws_kms_alias" "kms-ebs" {
  name = "alias/aws/ebs"
}

resource "aws_s3_object" "bucket_public_keys_readme" {
  bucket     = aws_s3_bucket.bucket.id
  key        = "public-keys/README.txt"
  content    = "Drop here the ssh public keys of the instances you want to control"
  kms_key_id = aws_kms_key.key.arn
}

resource "aws_s3_object" "bucket_public_keys" {
  for_each    = {for pk in var.public_keys:  pk.name => pk}
  bucket      = aws_s3_bucket.bucket.id
  key         = "public-keys/${each.value.name}.pub"
  content     = each.value.key
  kms_key_id  = aws_kms_key.key.arn
}

resource "aws_security_group" "bastion_host_security_group" {
  count       = var.bastion_security_group_id == "" ? 1 : 0
  description = "Enable SSH access to the bastion host from external via SSH port"
  name        = "${local.name_prefix}-host"
  vpc_id      = var.vpc_id

  tags = merge(var.tags)
}

resource "aws_security_group_rule" "ingress_bastion" {
  count            = var.bastion_security_group_id == "" ? 1 : 0
  description      = "Incoming traffic to bastion"
  type             = "ingress"
  from_port        = var.public_ssh_port
  to_port          = var.public_ssh_port
  protocol         = "TCP"
  cidr_blocks      = data.aws_subnet.subnets.*.cidr_block
  ipv6_cidr_blocks = data.aws_subnet.subnets.*.ipv6_cidr_block

  security_group_id = local.security_group
}

resource "aws_security_group_rule" "egress_bastion" {
  count       = var.bastion_security_group_id == "" ? 1 : 0
  description = "Outgoing traffic from bastion to instances"
  type        = "egress"
  from_port   = "0"
  to_port     = "65535"
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = local.security_group
}

resource "aws_security_group" "private_instances_security_group" {
  description = "Enable SSH access to the Private instances from the bastion via SSH port"
  name        = "${local.name_prefix}-priv-instances"
  vpc_id      = var.vpc_id

  tags = merge(var.tags)
}

resource "aws_security_group_rule" "ingress_instances" {
  description = "Incoming traffic from bastion"
  type        = "ingress"
  from_port   = var.private_ssh_port
  to_port     = var.private_ssh_port
  protocol    = "TCP"

  source_security_group_id = local.security_group

  security_group_id = aws_security_group.private_instances_security_group.id
}

data "aws_iam_policy_document" "assume_policy_document" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "bastion_host_role" {
  name                 = var.bastion_iam_role_name
  path                 = "/"
  assume_role_policy   = data.aws_iam_policy_document.assume_policy_document.json
  permissions_boundary = var.bastion_iam_permissions_boundary
}

data "aws_iam_policy_document" "bastion_host_policy_document" {

  statement {
    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl"
    ]
    resources = ["${aws_s3_bucket.bucket.arn}/logs/*"]
  }

  statement {
    actions = [
      "s3:GetObject"
    ]
    resources = ["${aws_s3_bucket.bucket.arn}/public-keys/*"]
  }

  statement {
    actions = [
      "s3:ListBucket"
    ]
    resources = [
    aws_s3_bucket.bucket.arn]

    condition {
      test     = "ForAnyValue:StringEquals"
      values   = ["public-keys/"]
      variable = "s3:prefix"
    }
  }

  statement {
    actions = [

      "kms:Encrypt",
      "kms:Decrypt"
    ]
    resources = [aws_kms_key.key.arn]
  }

}

resource "aws_iam_policy" "bastion_host_policy" {
  name   = var.bastion_iam_policy_name
  policy = data.aws_iam_policy_document.bastion_host_policy_document.json
}

resource "aws_iam_role_policy_attachment" "bastion_host" {
  policy_arn = aws_iam_policy.bastion_host_policy.arn
  role       = aws_iam_role.bastion_host_role.name
}

resource "aws_route53_record" "bastion_record_name" {
  count   = var.create_dns_record && local.has_lb ? 1 : 0
  name    = var.bastion_record_name
  zone_id = var.hosted_zone_id
  type    = "A"

  alias {
    evaluate_target_health = true
    name                   = local.has_injected_lb ? var.bastion_nlb.dns_name : aws_lb.bastion_lb[0].dns_name
    zone_id                = local.has_injected_lb ? var.bastion_nlb.zone_id : aws_lb.bastion_lb[0].zone_id
  }
}

resource "aws_lb" "bastion_lb" {
  count = var.create_lb ? 1 : 0

  internal = var.is_lb_private
  name     = "${local.name_prefix}-lb"

  subnets = var.elb_subnets

  load_balancer_type = "network"
  tags               = merge(var.tags)
}

resource "aws_lb_target_group" "bastion_lb_target_group" {
  name        = "${local.name_prefix}-lb-target"
  count       = local.has_lb ? 1 : 0
  port        = var.public_ssh_port
  protocol    = "TCP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    port     = "traffic-port"
    protocol = "TCP"
  }

  tags = merge(var.tags)
}

resource "aws_lb_listener" "bastion_lb_listener_22" {
  count = local.has_lb ? 1 : 0
  default_action {
    target_group_arn = aws_lb_target_group.bastion_lb_target_group[0].arn
    type             = "forward"
  }

  load_balancer_arn = local.has_injected_lb ? var.bastion_nlb.arn : aws_lb.bastion_lb[0].arn
  port              = var.public_ssh_port
  protocol          = "TCP"
}

resource "aws_iam_instance_profile" "bastion_host_profile" {
  role = aws_iam_role.bastion_host_role.name
  path = "/"
}

resource "aws_launch_template" "bastion_launch_template" {
  name_prefix            = var.bastion_launch_template_name
  image_id               = var.bastion_ami != "" ? var.bastion_ami : data.aws_ami.amazon-linux-2.id
  instance_type          = var.instance_type
  update_default_version = true
  monitoring {
    enabled = true
  }
  network_interfaces {
    associate_public_ip_address = var.associate_public_ip_address
    security_groups             = concat([local.security_group], var.bastion_additional_security_groups)
    delete_on_termination       = true
  }
  iam_instance_profile {
    name = aws_iam_instance_profile.bastion_host_profile.name
  }
  key_name = var.bastion_host_key_pair

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    aws_region              = var.aws_region
    bucket_name             = var.bucket_name
    extra_user_data_content = var.extra_user_data_content
    allow_ssh_commands      = lower(var.allow_ssh_commands)
    public_ssh_port         = var.public_ssh_port
    sync_logs_cron_job      = var.enable_logs_s3_sync ? "*/5 * * * * /usr/bin/bastion/sync_s3" : ""
    bastion_cidrs           = join(" ", concat(data.aws_subnet.subnets.*.cidr_block, data.aws_subnet.subnets.*.ipv6_cidr_block))
  }))

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = var.disk_size
      volume_type           = "gp2"
      delete_on_termination = true
      encrypted             = var.disk_encrypt
      kms_key_id            = var.disk_encrypt ? data.aws_kms_alias.kms-ebs.target_key_arn : ""
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags          = merge(tomap({ "Name" = var.bastion_launch_template_name }), merge(var.tags))
  }

  tag_specifications {
    resource_type = "volume"
    tags          = merge(tomap({ "Name" = var.bastion_launch_template_name }), merge(var.tags))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "bastion_auto_scaling_group" {
  name_prefix = "ASG-${local.name_prefix}"
  launch_template {
    id      = aws_launch_template.bastion_launch_template.id
    version = "$Latest"
  }
  max_size         = var.bastion_instance_count
  min_size         = var.bastion_instance_count
  desired_capacity = var.bastion_instance_count

  vpc_zone_identifier = var.auto_scaling_group_subnets

  default_cooldown          = 180
  health_check_grace_period = 180
  health_check_type         = "EC2"

  target_group_arns = local.has_lb ? [
    aws_lb_target_group.bastion_lb_target_group[0].arn,
  ] : []

  termination_policies = [
    "OldestLaunchConfiguration",
  ]

  enabled_metrics = var.enabled_metrics

  dynamic "tag" {
    for_each = var.tags

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  tag {
    key                 = "Name"
    value               = "ASG-${local.name_prefix}"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [aws_s3_bucket.bucket]
}

data "aws_instances" "bastion_instance_data" {
  instance_tags = {
    Name = aws_autoscaling_group.bastion_auto_scaling_group.name
  }
}

