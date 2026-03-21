resource "google_compute_network" "atlantis-demo-vpc-backend" {
  name                    = "atlantis-demo-vpc-backend"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "atlantis-demo-vpc-backend-subnet" {
  name          = "atlantis-demo-vpc-backend-subnet"
  region        = var.default_region
  network       = google_compute_network.atlantis-demo-vpc-backend.id
  ip_cidr_range = var.ip_cidr_range
}

