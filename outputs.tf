# ========================================
# Outputs
# ========================================

# ========================================
# General Information
# ========================================

output "group_replication_uuid" {
  description = "UUID used for Group Replication"
  value       = local.group_uuid
}

# ========================================
# Region 1 Outputs
# ========================================

output "region1_vpc_id" {
  description = "VPC ID in Region 1"
  value       = module.vpc_region1.vpc_id
}

output "region1_vpc_cidr" {
  description = "VPC CIDR in Region 1"
  value       = module.vpc_region1.vpc_cidr
}

output "region1_rds_endpoint" {
  description = "RDS endpoint in Region 1"
  value       = module.rds_region1.db_instance_endpoint
}

output "region1_rds_address" {
  description = "RDS address in Region 1"
  value       = module.rds_region1.db_instance_address
}

output "region1_rds_port" {
  description = "RDS port in Region 1"
  value       = module.rds_region1.db_instance_port
}

output "region1_parameter_group" {
  description = "Parameter group name in Region 1"
  value       = module.rds_region1.db_parameter_group_name
}

# ========================================
# Region 2 Outputs
# ========================================

output "region2_vpc_id" {
  description = "VPC ID in Region 2"
  value       = module.vpc_region2.vpc_id
}

output "region2_vpc_cidr" {
  description = "VPC CIDR in Region 2"
  value       = module.vpc_region2.vpc_cidr
}

output "region2_rds_endpoint" {
  description = "RDS endpoint in Region 2"
  value       = module.rds_region2.db_instance_endpoint
}

output "region2_rds_address" {
  description = "RDS address in Region 2"
  value       = module.rds_region2.db_instance_address
}

output "region2_rds_port" {
  description = "RDS port in Region 2"
  value       = module.rds_region2.db_instance_port
}

output "region2_parameter_group" {
  description = "Parameter group name in Region 2"
  value       = module.rds_region2.db_parameter_group_name
}

# ========================================
# VPC Peering
# ========================================

output "vpc_peering_id" {
  description = "VPC Peering Connection ID"
  value       = module.vpc_peering.peering_connection_id
}

output "vpc_peering_status" {
  description = "VPC Peering Connection Status"
  value       = module.vpc_peering.peering_connection_status
}

# ========================================
# Connection Commands
# ========================================

output "region1_mysql_command" {
  description = "MySQL connection command for Region 1"
  value       = "mysql -h ${module.rds_region1.db_instance_address} -P ${module.rds_region1.db_instance_port} -u ${var.db_username} -p"
}

output "region2_mysql_command" {
  description = "MySQL connection command for Region 2"
  value       = "mysql -h ${module.rds_region2.db_instance_address} -P ${module.rds_region2.db_instance_port} -u ${var.db_username} -p"
}

# ========================================
# Next Steps
# ========================================

output "next_steps" {
  description = "Commands to configure Group Replication"
  value = <<-EOT
    ==========================================
    Infrastructure Created Successfully!
    ==========================================
    
    Group Replication UUID: ${local.group_uuid}
    
    Region 1 (${var.region1}):
      VPC: ${module.vpc_region1.vpc_id} (${module.vpc_region1.vpc_cidr})
      RDS: ${module.rds_region1.db_instance_address}
    
    Region 2 (${var.region2}):
      VPC: ${module.vpc_region2.vpc_id} (${module.vpc_region2.vpc_cidr})
      RDS: ${module.rds_region2.db_instance_address}
    
    VPC Peering: ${module.vpc_peering.peering_connection_id} (${module.vpc_peering.peering_connection_status})
    
    ==========================================
    Next Steps:
    ==========================================
    
    1. Run the setup script to configure Group Replication:
       cd scripts && ./setup_replication.sh
    
    2. Or manually configure:
       - Update parameter groups with group seeds
       - Reboot RDS instances
       - Initialize Group Replication on Region 1
       - Join Region 2 to the group
    
    3. Test the replication:
       cd scripts && ./test_replication.sh
    
    ==========================================
  EOT
}
