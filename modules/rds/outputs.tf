output "db_instance_id" {
  description = "ID of the RDS instance"
  value       = aws_db_instance.main.id
}

output "db_instance_arn" {
  description = "ARN of the RDS instance"
  value       = aws_db_instance.main.arn
}

output "db_instance_endpoint" {
  description = "Connection endpoint (host:port)"
  value       = aws_db_instance.main.endpoint
}

output "db_instance_address" {
  description = "Hostname of the RDS instance"
  value       = aws_db_instance.main.address
}

output "db_instance_port" {
  description = "Port of the RDS instance"
  value       = aws_db_instance.main.port
}

output "db_parameter_group_name" {
  description = "Name of the DB parameter group"
  value       = aws_db_parameter_group.main.name
}

output "db_instance_status" {
  description = "Status of the RDS instance"
  value       = aws_db_instance.main.status
}

output "db_instance_resource_id" {
  description = "Resource ID of the RDS instance"
  value       = aws_db_instance.main.resource_id
}
