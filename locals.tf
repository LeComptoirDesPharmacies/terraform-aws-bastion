locals {
  name_prefix    = var.bastion_launch_template_name

  has_created_lb = var.create_lb ? true : false
  has_injected_lb = var.bastion_nlb != null ? true : false
  has_lb = local.has_created_lb || local.has_injected_lb
  security_group = join("", flatten([aws_security_group.bastion_host_security_group[*].id, var.bastion_security_group_id]))
}