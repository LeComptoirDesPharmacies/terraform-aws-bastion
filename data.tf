# AWS publishes every AL2023 release once per kernel line (6.1, 6.12, 6.18) at the same time:
# the kernel must be part of the filter, otherwise most_recent picks one of them at random
data "aws_ami" "amazon-linux-2023" {
  most_recent = true
  owners      = ["amazon"]
  name_regex  = "^al2023-ami-2023\\.[0-9.]+-kernel-6\\.18-x86_64$"

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

data "aws_subnet" "subnets" {
  count = length(var.elb_subnets)
  id    = var.elb_subnets[count.index]
}

