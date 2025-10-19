# ========================================
# Region 1: US-EAST-1
# ========================================

module "vpc_region1" {
  source = "./modules/vpc"

  providers = {
    aws = aws.region1
  }

  name_prefix            = "${var.project_name}-${var.region1}"
  vpc_cidr               = var.region1_vpc_cidr
  subnet_cidrs           = var.region1_subnet_cidrs
  availability_zones     = local.region1_azs
  peer_vpc_cidr          = var.region2_vpc_cidr
  allowed_cidr_blocks    = var.allowed_cidr_blocks
  map_public_ip_on_launch = var.db_publicly_accessible

  tags = merge(
    local.common_tags,
    {
      Region = var.region1
    }
  )
}

module "rds_region1" {
  source = "./modules/rds"

  providers = {
    aws = aws.region1
  }

  name_prefix          = "${var.project_name}-${var.region1}"
  instance_identifier  = "${var.project_name}-${var.region1}"
  engine_version       = var.db_engine_version
  instance_class       = var.db_instance_class
  allocated_storage    = var.db_allocated_storage
  db_username          = var.db_username
  db_password          = var.db_password
  db_subnet_group_name = module.vpc_region1.db_subnet_group_name
  security_group_id    = module.vpc_region1.security_group_id
  publicly_accessible  = var.db_publicly_accessible

  backup_retention_period = var.db_backup_retention_period
  skip_final_snapshot     = var.skip_final_snapshot

  group_replication_uuid  = local.group_uuid
  # group_replication_local_address  = "${var.project_name}-${var.region1}.${data.aws_region.region1.name}.rds.amazonaws.com:33061"
  group_replication_seeds = ""  # Will be updated after both instances are created

  tags = merge(
    local.common_tags,
    {
      Region = var.region1
    }
  )

  depends_on = [module.vpc_region1]
}
