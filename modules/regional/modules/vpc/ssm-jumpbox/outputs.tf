output "launch_template_id" {
  value = var.create_ssm_jumpbox ? aws_launch_template.ssm_jumpbox[0].id : null
}

output "autoscaling_group_name" {
  value = var.create_ssm_jumpbox ? aws_autoscaling_group.ssm_jumpbox[0].name : null
}

output "security_group" {
  value = var.create_ssm_jumpbox ? aws_security_group.ssm_jumpbox[0] : null
}