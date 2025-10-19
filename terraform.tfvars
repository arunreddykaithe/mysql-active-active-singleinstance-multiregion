# ========================================
# MySQL Active-Active Configuration Example
# ========================================
# Copy this file to terraform.tfvars and customize

# Environment
environment  = "production"  # or "development", "staging"
project_name = "mysql-active"

# AWS Regions
region1 = "us-east-2"
region2 = "us-west-2"

# ========================================
# Network Configuration
# ========================================
# ⚠️ IMPORTANT: Ensure these CIDRs don't overlap with existing VPCs!
# These default values (10.10.0.0/24 and 10.11.0.0/24) are chosen
# because they don't overlap with your existing VPCs shown in screenshots

region1_vpc_cidr = "10.10.0.0/24"  # 256 IPs for Region 1
region2_vpc_cidr = "10.11.0.0/24"  # 256 IPs for Region 2

# Subnet CIDRs (3 subnets per region, 32 IPs each)
region1_subnet_cidrs = ["10.10.0.0/27", "10.10.0.32/27", "10.10.0.64/27"]
region2_subnet_cidrs = ["10.11.0.0/27", "10.11.0.32/27", "10.11.0.64/27"]

# ========================================
# RDS Configuration
# ========================================

# Instance class (adjust based on your needs)
# - db.t3.small:  2 vCPU, 2GB RAM (~$30/month per instance)
# - db.t3.medium: 2 vCPU, 4GB RAM (~$60/month per instance)
# - db.t3.large:  2 vCPU, 8GB RAM (~$120/month per instance)
# - db.r5.large:  2 vCPU, 16GB RAM (~$175/month per instance)
db_instance_class = "db.t3.medium"

# Storage configuration
db_allocated_storage = 100  # GB (minimum 20, maximum 65536)

# MySQL version - MUST be 8.0.35 or higher for active-active
# Available versions: 8.0.35, 8.0.36, 8.0.37, 8.0.38, 8.0.39 (recommended)
db_engine_version = "8.0.39"

# Database credentials
db_username = "admin"  # Cannot be 'rdsgrprepladmin' (reserved)
db_password = "Cr3ckiTifur3R3J3$u$0rG3d123!"  # ⚠️ MUST CHANGE THIS!

# Backup configuration
db_backup_retention_period = 7  # Days (0-35, 0 = disabled)

# ========================================
# Security Configuration
# ========================================

# Public accessibility
# - true: RDS instances will have public IPs (easier for testing)
# - false: RDS instances will be private (recommended for production)
db_publicly_accessible = true

# Allowed CIDR blocks for MySQL access (port 3306)
# ⚠️ For production, restrict to your IP or VPN range!
# Examples:
#   - ["0.0.0.0/0"]           - Allow from anywhere (INSECURE - testing only!)
#   - ["203.0.113.0/24"]      - Allow from specific network
#   - ["203.0.113.5/32"]      - Allow from single IP
allowed_cidr_blocks = ["0.0.0.0/0"]

# ========================================
# Deletion Protection
# ========================================

# Skip final snapshot on deletion
# - true:  No snapshot created when destroying (faster, data lost)
# - false: Create final snapshot before deletion (slower, data saved)
skip_final_snapshot = true  # ⚠️ Set to false for production!

# ========================================
# Group Replication
# ========================================

# Group Replication UUID
# - Leave empty ("") to auto-generate a UUID
# - Or provide your own: "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee"
group_replication_group_name = ""

# ========================================
# Additional Tags
# ========================================

additional_tags = {
  Owner       = "DevOps Team"
  CostCenter  = "Engineering"
  Compliance  = "Required"
  Application = "MySQL-Cluster"
  Department  = "CP"
}

# ========================================
# PRODUCTION RECOMMENDATIONS
# ========================================
# For production environments, consider:
#
# 1. Security:
#    - db_publicly_accessible = false
#    - allowed_cidr_blocks = ["10.0.0.0/8"]  # VPN/Internal only
#    - skip_final_snapshot = false
#
# 2. Performance:
#    - db_instance_class = "db.r5.large" or higher
#    - db_allocated_storage = 500 or higher
#
# 3. High Availability:
#    - Add Multi-AZ within each region (requires code modification)
#    - Enable deletion_protection = true (requires code modification)
#
# 4. Monitoring:
#    - Enable Performance Insights (requires code modification)
#    - Enable Enhanced Monitoring (requires code modification)
#    - Set up CloudWatch alarms
#
# 5. Backup:
#    - db_backup_retention_period = 30
#    - Consider automated snapshot copies to S3
#
# 6. Security:
#    - Use AWS Secrets Manager for db_password
#    - Enable storage_encrypted = true (already default in code)
#    - Implement strict IAM policies
#
# ========================================
