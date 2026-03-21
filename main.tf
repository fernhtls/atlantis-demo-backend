locals {
  gcp_services = [
    "compute.googleapis.com",
    "secretmanager.googleapis.com",
    "dns.googleapis.com",
    "domains.googleapis.com"
  ]
}

terraform {
  backend "gcs" {
    bucket = "atlantis-demo-tfstates"
    prefix = "atlantis-demo-backend" # project name, puts a folder below
  }
}

provider "google" {
  project = var.gcp_project_id
  region  = var.default_region
  zone    = var.default_location
  default_labels = {
    terraform = "true"
    app       = "atlantis-demo"
  }
}

provider "google-beta" {
  project = var.gcp_project_id
  region  = var.default_region
  zone    = var.default_location
  default_labels = {
    terraform = "true"
    app       = "atlantis-demo"
  }
}

data "google_project" "project" {}

# Enabling GCP services
resource "google_project_service" "service" {
  for_each           = toset(local.gcp_services)
  service            = each.key
  disable_on_destroy = false
}
