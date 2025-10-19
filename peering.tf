# ========================================
# VPC Peering Between Regions
# ========================================

module "vpc_peering" {
  source = "./modules/peering"

  providers = {
    aws.requester = aws.region1
    aws.accepter  = aws.region2
  }

  peering_name = "${var.project_name}-peering"

  requester_vpc_id         = module.vpc_region1.vpc_id
  requester_vpc_cidr       = module.vpc_region1.vpc_cidr
  requester_route_table_id = module.vpc_region1.route_table_id

  accepter_vpc_id         = module.vpc_region2.vpc_id
  accepter_vpc_cidr       = module.vpc_region2.vpc_cidr
  accepter_route_table_id = module.vpc_region2.route_table_id
  accepter_region         = var.region2

  tags = local.common_tags

  depends_on = [
    module.vpc_region1,
    module.vpc_region2
  ]
}
