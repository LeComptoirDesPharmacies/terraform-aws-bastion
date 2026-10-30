variable "bucket_name" {
  description = "Bucket name were the bastion will store the logs"
}

variable "bucket_versioning" {
  default     = true
  description = "Enable bucket versioning or not"
}

variable "bucket_force_destroy" {
  default     = false
  description = "The bucket and all objects should be destroyed when using true"
}

variable "tags" {
  description = "A mapping of tags to assign"
  default     = {}
  type        = map(string)
}

variable "aws_region" {
  description = "Region within the module will run"
  type        = string
}

variable "cidrs" {
  description = "List of CIDRs than can access to the bastion. Default : 0.0.0.0/0"
  type        = list(string)

  default = [
    "0.0.0.0/0",
  ]
}

variable "create_lb" {
  description = "Choose if you want to create a load balancer for the bastion. If true, you can setup DNS and 'is_lb_private', 'elb_subnets', 'auto_scaling_group_subnets' are mandatory"
  type        = bool
}

variable "is_lb_private" {
  description = "If TRUE the load balancer scheme will be \"internal\" else \"internet-facing\""
  default     = true
}

variable "vpc_id" {
  description = "VPC id were we'll deploy the bastion"
}

variable "bastion_host_key_pair" {
  description = "Select the key pair to use to launch the bastion host"
}

variable "hosted_zone_id" {
  description = "Name of the hosted zone were we'll register the bastion DNS name"
  default     = ""
}

variable "bastion_record_name" {
  description = "DNS record name to use for the bastion"
  default     = ""
}

variable "bastion_launch_template_name" {
  description = "Bastion Launch template Name, will also be used for the ASG"
  default     = "bastion-lt"
}

variable "bastion_security_group_id" {
  description = "Custom security group to use"
  default     = ""
}

variable "bastion_additional_security_groups" {
  description = "List of additional security groups to attach to the launch template"
  type        = list(string)
  default     = []
}

variable "bastion_ami" {
  type        = string
  description = "The AMI that the Bastion Host will use. It must be an Amazon Linux 2023 AMI: the user data only supports this distribution."
}

variable "bastion_nlb" {
  description = "A network loadbalancer has been created if this value is different from null"
  default     = null
}

variable "elb_subnets" {
  type        = list(string)
  description = "List of subnet were the ELB will be deployed"
  default     = []
}

variable "auto_scaling_group_subnets" {
  type        = list(string)
  description = "List of subnet were the Auto Scalling Group will deploy the instances"
}

variable "associate_public_ip_address" {
  default = true
}

variable "bastion_instance_count" {
  default = 1
}

variable "create_dns_record" {
  description = "Choose if you want to create a record name for the bastion (LB). If true 'hosted_zone_id' and 'bastion_record_name' are mandatory and 'create_lb' should be true"
}

variable "log_auto_clean" {
  description = "Enable or not the lifecycle"
  default     = false
}

variable "log_standard_ia_days" {
  description = "Number of days before moving logs to IA Storage"
  default     = 30
}

variable "log_glacier_days" {
  description = "Number of days before moving logs to Glacier"
  default     = 60
}

variable "log_expiry_days" {
  description = "Number of days before logs expiration"
  default     = 90
}

variable "public_ssh_port" {
  description = "Set the SSH port to use from desktop to the bastion"
  default     = 22
}

variable "private_ssh_port" {
  description = "Set the SSH port to use between the bastion and private instance"
  default     = 22
}

variable "extra_user_data_content" {
  description = "Additional scripting to pass to the bastion host. For example, this can include installing postgresql for the `psql` command."
  type        = string
  default     = ""
}

variable "fail2ban_ddos_ignoreip" {
  description = "List of trusted IPs/CIDRs exempted from the fail2ban connection-noise jails (sshd-ddos and recidive) but NOT from the authentication jail. Use for legitimate automation that opens TCP connections without completing the SSH handshake (e.g. Fivetran shared egress '35.235.32.144/29'). These IPs are still banned on real SSH authentication failures, so a shared IP is not granted blanket immunity."
  type        = list(string)
  default     = []
}

variable "allow_ssh_commands" {
  description = "Allows the SSH user to execute one-off commands. Pass true to enable. Warning: These commands are not logged and increase the vulnerability of the system. Use at your own discretion."
  type        = bool
  default     = false
}

variable "bastion_iam_role_name" {
  description = "IAM role name to create"
  type        = string
  default     = null
}

variable "bastion_iam_policy_name" {
  description = "IAM policy name to create for granting the instance role access to the bucket"
  default     = "BastionHost"
}

variable "bastion_iam_permissions_boundary" {
  description = "IAM Role Permissions Boundary to constrain the bastion host role"
  default     = ""
}

variable "enabled_metrics" {
  description = "List of autoscaling group metrics to enable."
  type        = list(string)
  default     = []
}

variable "public_keys" {
  description = "Default public keys who are authorized to reach bastion"
  type        = list(object({
    name = string,
    key  = string
  }))
  default     = []
}

variable "instance_type" {
  description = "Instance size of the bastion"
  default     = "t2.nano"
}

variable "disk_encrypt" {
  description = "Instance EBS encrypt"
  type        = bool
  default     = true
}

variable "disk_size" {
  description = "Root EBS size in GB"
  type        = number
  default     = 8
}

variable "enable_logs_s3_sync" {
  description = "Enable cron job to copy logs to S3"
  type        = bool
  default     = true
}

variable "kms_enable_key_rotation" {
  description = "Enable key rotation for the KMS key"
  type        = bool
  default     = false
}

variable "ipv6_cidrs" {
  description = "List of IPv6 CIDRs than can access to the bastion. Default : ::/0"
  type        = list(string)

  default = [
    "::/0",
  ]
}
