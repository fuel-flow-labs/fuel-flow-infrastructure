output "instance_ids" {
  description = "IDs of EC2 instances"
  value       = aws_instance.app_server[*].id
}

output "public_ips" {
  description = "Public IP addresses of EC2 instances"
  value       = aws_instance.app_server[*].public_ip
}

output "private_ips" {
  description = "Private IP addresses of EC2 instances"
  value       = aws_instance.app_server[*].private_ip
}

output "security_group_id" {
  description = "Security group ID for EC2 instances"
  value       = aws_security_group.ec2_sg.id
}
