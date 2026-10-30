# Latest Amazon Linux 2023 AMI published by AWS, pinned to a kernel line
data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-${var.al2023_kernel}-x86_64"
}

data "aws_subnet" "subnets" {
  count = length(var.elb_subnets)
  id    = var.elb_subnets[count.index]
}

