module "ecr_vote" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "3.2.0"

  repository_name               = "vote-app"
  repository_force_delete       = true
  repository_image_scan_on_push = true
  create_lifecycle_policy       = false
}

module "ecr_worker" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "3.2.0"

  repository_name               = "worker-app"
  repository_force_delete       = true
  repository_image_scan_on_push = true
  create_lifecycle_policy       = false
}

module "ecr_result" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "3.2.0"

  repository_name               = "result-app"
  repository_force_delete       = true
  repository_image_scan_on_push = true
  create_lifecycle_policy       = false
}
