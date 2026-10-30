data "aws_subnet" "subnets" {
  count = length(var.elb_subnets)
  id    = var.elb_subnets[count.index]
}

