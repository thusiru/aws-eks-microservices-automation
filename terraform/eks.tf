module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.20.0"

  name               = "eks-microservices"
  kubernetes_version = "1.35"

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.public_subnets

  endpoint_public_access                   = true
  enable_cluster_creator_admin_permissions = true
  enable_irsa                              = true

  eks_managed_node_groups = {
    app_nodes = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"

      min_size     = 1
      max_size     = 3
      desired_size = 2
    }
  }
}
