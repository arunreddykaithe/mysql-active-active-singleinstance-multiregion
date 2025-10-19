# ========================================
# General Variables
# ========================================

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "mysql-active"
}

# ========================================
# Region Configuration
# ========================================

variable "region1" {
  description = "Primary AWS region"
  type        = string
  default     = "us-east-1"
}

variable "region2" {
  description = "Secondary AWS region"
  type        = string
  default     = "us-west-2"
}

# ========================================
# Network Configuration
# ========================================

variable "region1_vpc_cidr" {
  description = "CIDR block for Region 1 VPC"
  type        = string
  default     = "10.10.0.0/24"
  
  validation {
    condition     = can(cidrhost(var.region1_vpc_cidr, 0))
    error_message = "Must be a valid CIDR block."
  }
}

variable "region2_vpc_cidr" {
  description = "CIDR block for Region 2 VPC"
  type        = string
  default     = "10.11.0.0/24"
  
  validation {
    condition     = can(cidrhost(var.region2_vpc_cidr, 0))
    error_message = "Must be a valid CIDR block."
  }
}

variable "region1_subnet_cidrs" {
  description = "CIDR blocks for Region 1 subnets"
  type        = list(string)
  default     = ["10.10.0.0/27", "10.10.0.32/27", "10.10.0.64/27"]
}

variable "region2_subnet_cidrs" {
  description = "CIDR blocks for Region 2 subnets"
  type        = list(string)
  default     = ["10.11.0.0/27", "10.11.0.32/27", "10.11.0.64/27"]
}

# ========================================
# RDS Configuration
# ========================================

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.medium"
  
  validation {
    condition     = can(regex("^db\\.", var.db_instance_class))
    error_message = "Must be a valid RDS instance class."
  }
}

variable "db_allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 100
  
  validation {
    condition     = var.db_allocated_storage >= 20 && var.db_allocated_storage <= 65536
    error_message = "Must be between 20 and 65536 GB."
  }
}

variable "db_engine_version" {
  description = "MySQL engine version (must be 8.0.35 or higher for active-active)"
  type        = string
  default     = "8.0.39"
  
  validation {
    condition     = can(regex("^8\\.0\\.(3[5-9]|[4-9][0-9])$", var.db_engine_version))
    error_message = "Must be MySQL 8.0.35 or higher for active-active support."
  }
}

variable "db_username" {
  description = "Master username for RDS (cannot be 'rdsgrprepladmin')"
  type        = string
  default     = "admin"
  
  validation {
    condition     = var.db_username != "rdsgrprepladmin"
    error_message = "Username cannot be 'rdsgrprepladmin' (reserved for Group Replication)."
  }
}

variable "db_password" {
  description = "Master password for RDS"
  type        = string
  sensitive   = true
  
  validation {
    condition     = length(var.db_password) >= 8
    error_message = "Password must be at least 8 characters long."
  }
}

variable "db_backup_retention_period" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7
  
  validation {
    condition     = var.db_backup_retention_period >= 0 && var.db_backup_retention_period <= 35
    error_message = "Must be between 0 and 35 days."
  }
}

variable "db_publicly_accessible" {
  description = "Whether RDS instances should be publicly accessible"
  type        = bool
  default     = true
}

variable "skip_final_snapshot" {
  description = "Whether to skip final snapshot on deletion"
  type        = bool
  default     = true
}

# ========================================
# Security Configuration
# ========================================

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access MySQL (for testing, use 0.0.0.0/0)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# ========================================
# Group Replication Configuration
# ========================================

variable "group_replication_group_name" {
  description = "UUID for Group Replication (leave empty to auto-generate)"
  type        = string
  default     = ""
  
  validation {
    condition     = var.group_replication_group_name == "" || can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.group_replication_group_name))
    error_message = "Must be a valid UUID or empty."
  }
}

# ========================================
# Tags
# ========================================

variable "additional_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
