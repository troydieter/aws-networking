terraform {
  backend "s3" {
    bucket  = "jennas-tf-statefiles-master"
    key     = "us-east-1/terraform.tfstate"
    region  = "us-east-1"
    profile = "default"
    encrypt = true
  }
}
