provider "aws" {
  alias   = "primary"
  region  = var.region_primary
  default_tags {
    tags = {
      owner       = var.owner
      project     = var.project
      environment = var.environment
      region      = var.region_primary
    }
  }
}

provider "aws" {
  alias   = "secondary"
  region  = var.region_secondary
  default_tags {
    tags = {
      owner       = var.owner
      project     = var.project
      environment = var.environment
      region      = var.region_secondary
    }
  }
}

provider "aws" {
  alias   = "accepter"
  region  = var.region_secondary
  default_tags {
    tags = {
      owner       = var.owner
      project     = var.project
      environment = var.environment
      region      = var.region_secondary
    }
  }
}