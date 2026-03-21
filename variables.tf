variable "gcp_project_id" {
  type    = string
  default = "atlantis-demo-backend"
}

variable "default_region" {
  type        = string
  description = "GCP default region to create resources"
  default     = "europe-west4"
}

variable "default_location" {
  type        = string
  description = "GCP default location to create resources"
  default     = "europe-west4-a"
}

variable "ip_cidr_range" {
  type        = string
  description = "Project CIDR range for creating a VPC"
  default     = "10.139.0.0/19"
}

// variable "atlantis_demo_dns_domain" {
//   type        = string
//   description = "DNS domain for the atlantis demo - used on LB creations and DNS record sets"
//   default     = "atlantis-demo-fsouza.nl"
// }
