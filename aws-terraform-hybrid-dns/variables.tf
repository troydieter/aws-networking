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

variable "accepter_vpc_id" {
  description = "VPC id that you want to peer with it"
  type        = string
}

variable "accepter_route_table_id" {
  description = "Route table id of the accepter that you want to peer with it"
  type        = string
}

variable "onpremdnsa_priv_ip" {
  description = "Private IP Address of micros4l-onpremdnsa"
  type        = string
}

variable "onpremdnsb_priv_ip" {
  description = "Private IP Address of micros4l-onpremdnsb"
  type        = string
}
