variable "owner" {
  default     = "Troy Dieter"
  description = "Deployer of these resources"
}

variable "project" {
  default     = "aws-terraform-hybrid-dns"
  description = "Project we're deploying"
}

variable "environment" {
  default     = "dev"
  description = "Environment"
}

variable "region_primary" {
  default     = "us-east-1"
  description = "The primary region to deploy to"
}

variable "region_secondary" {
  default     = "us-east-2"
  description = "The secondary region to deploy to"
}