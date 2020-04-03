# https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/2.32.0
module "sandbox_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.32.0"

  name = local.prefix
  cidr = "10.0.0.0/16"
  tags = local.tags

  private_subnet_tags = {"kubernetes.io/cluster/muradkorejo-eks" = "shared"}
  public_subnet_tags  = {"kubernetes.io/cluster/muradkorejo-eks" = "shared"}

  azs             = ["us-east-1c", "us-east-1d", "us-east-1f"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_dns_hostnames = true
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_s3_endpoint   = true
}

module "sandbox_eks" {
  source = "../../modules/eks"

  prefix = local.prefix
  tags   = local.tags

  vpc_id     = module.sandbox_vpc.vpc_id
  subnet_ids = module.sandbox_vpc.private_subnets

  node_group_ssh_key = "muradkorejo"
}