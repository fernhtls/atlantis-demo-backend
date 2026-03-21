### Cloud NAT - for internal VMs to access the internet through the NAT routers
### https://cloud.google.com/architecture/building-internet-connectivity-for-private-vms#deploying_cloud_nat_for_fetching

resource "google_compute_router" "atlantis-demo-nat-router" {
  name    = "atlantis-demo-nat-router"
  network = google_compute_network.atlantis-demo-vpc-backend.name
  region  = var.default_region
}

resource "google_compute_router_nat" "atlantis-demo-nat-config" {
  name                   = "atlantis-demo-nat-config"
  router                 = google_compute_router.atlantis-demo-nat-router.name
  region                 = google_compute_subnetwork.atlantis-demo-vpc-backend-subnet.region
  nat_ip_allocate_option = "AUTO_ONLY"

  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  subnetwork {
    name                    = google_compute_subnetwork.atlantis-demo-vpc-backend-subnet.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

