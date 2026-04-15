locals {
  repos_allowlist = [
    "github.com/fernhtls/atlantis-demo-app-infra"
  ]
  github_hook_whitelist = [
    "192.30.252.0/22",
    "185.199.108.0/22",
    "140.82.112.0/20",
    "143.55.64.0/20"
  ]
}

resource "google_compute_address" "atlantis-internal-ip" {
  name         = "atlantis-internal-ip"
  description  = "Internal IP for atlantis"
  region       = var.default_region
  address_type = "INTERNAL"
  subnetwork   = google_compute_subnetwork.atlantis-demo-vpc-backend-subnet.id
}

data "google_compute_image" "debian12-bookworm" {
  family  = "debian-12"
  project = "debian-cloud"
}

resource "google_compute_disk" "atlantis-disk" {
  name                      = "atlantis-disk"
  type                      = "pd-ssd"
  zone                      = var.default_location
  image                     = data.google_compute_image.debian12-bookworm.name
  physical_block_size_bytes = 4096
  size                      = 15 # GB
  labels = {
    purpose = "atlantis"
  }
}

resource "google_compute_instance" "atlantis-host" {
  name         = "atlantis-host"
  machine_type = "e2-micro"
  zone         = var.default_location

  tags = ["atlantis", "http-server", "https-server"]

  allow_stopping_for_update = true

  boot_disk {
    auto_delete = false
    source      = google_compute_disk.atlantis-disk.self_link
  }

  network_interface {
    network    = google_compute_network.atlantis-demo-vpc-backend.name
    subnetwork = google_compute_subnetwork.atlantis-demo-vpc-backend-subnet.name
    network_ip = google_compute_address.atlantis-internal-ip.address
  }

  metadata = {
    purpose = "atlantis"
  }

  metadata_startup_script = templatefile(
    "./scripts/startup_script_atlantis.sh",
    {
      gh_token_secret_name      = google_secret_manager_secret.gh-token.secret_id
      webhook_token_secret_name = google_secret_manager_secret.webhook-token.secret_id
      PROJECT_ID                = data.google_project.project.project_id
      repos_allowlist           = join(",", local.repos_allowlist)
    }
  )

  service_account {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    email  = google_service_account.atlantis-sa.email
    scopes = ["cloud-platform"]
  }

  ### Added to prevent changes when adding ssh-keys for external access
  lifecycle {
    ignore_changes = [
      metadata
    ]
  }

  depends_on = [
    google_secret_manager_secret_version.gh-token-version,
    google_secret_manager_secret_version.webhook-token-version,
    google_compute_router_nat.atlantis-demo-nat-config,
    module.enable-services.google_project_service
  ]
  # Best practice with gcp is to actually just use the startup-script
  # as there's no need for external connections and with private instances
  # it would not work at all, as the remote-exec has to do ssh to the instance anyway
  # so it could be even considered not a good practice
  // provisioner "remote-exec" {
  //   # Provisioner connection block
  //   connection {
  //     type        = "ssh"
  //     user        = "root"
  //     private_key = module.atlantis-demo-ssl-cert.private_key_pem
  //     host        = <remote ip>
  //   }
  //   inline = ["echo \"hello\""]
  // }
  // provisioner "local-exec" {
  //  # just local exection where terraform is running
  //  # no config for any ssh connectivity nor nothing
  // }
}

// ### Allow ip blocks from cloud shell only
resource "google_compute_firewall" "atlantis-cloud-shell-rule" {
  name          = "atlantis-cloud-shell-rule"
  network       = google_compute_network.atlantis-demo-vpc-backend.name
  description   = "Firewall rule to allow cloud shell to connect to our atlantis server"
  direction     = "INGRESS"
  target_tags   = ["atlantis"]
  source_ranges = ["35.235.240.0/20"]
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

### Allow only IPs from github
resource "google_compute_firewall" "atlantis-github-cidr-rule" {
  name          = "atlantis-github-cidr-rule"
  network       = google_compute_network.atlantis-demo-vpc-backend.name
  description   = "Firewall rule to allow Github CIDR"
  direction     = "INGRESS"
  target_tags   = ["atlantis", "http-server"]
  source_ranges = local.github_hook_whitelist
  allow {
    protocol = "tcp"
    ports    = ["4141"]
  }

  allow {
    protocol = "udp"
    ports    = ["4141"]
  }
}

#### Https setup
resource "google_compute_instance_group" "atlantis-group" {
  name        = "atlantis-group"
  description = "Atlantis instance group"
  zone        = var.default_location
  network     = google_compute_network.atlantis-demo-vpc-backend.id

  instances = [
    google_compute_instance.atlantis-host.self_link
  ]

  named_port {
    name = "http"
    port = "4141"
  }

}

### Firewall rule for the health check system
resource "google_compute_firewall" "atlantis-allow-health-check" {
  name          = "atlantis-allow-health-check"
  direction     = "INGRESS"
  network       = google_compute_network.atlantis-demo-vpc-backend.name
  priority      = 1000
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  target_tags   = ["atlantis"]
  allow {
    ports    = ["4141"]
    protocol = "tcp"
  }
}

### Instance health check
resource "google_compute_health_check" "atlantis-http-health-check" {
  name               = "atlantis-http-basic-check"
  check_interval_sec = 10
  healthy_threshold  = 2
  tcp_health_check {
    port = "4141"
  }
  timeout_sec         = 5
  unhealthy_threshold = 5
  log_config {
    enable = true
  }
}

### Backend service - pointing to http
resource "google_compute_backend_service" "atlantis-backend-service" {
  name                            = "atlantis-backend-service"
  connection_draining_timeout_sec = 0
  health_checks                   = [google_compute_health_check.atlantis-http-health-check.id]
  load_balancing_scheme           = "EXTERNAL_MANAGED"
  port_name                       = "http"
  protocol                        = "HTTP"
  session_affinity                = "NONE"
  timeout_sec                     = 30
  security_policy                 = google_compute_security_policy.atlantis-demo-denyall-and-whitelist.self_link
  backend {
    group           = google_compute_instance_group.atlantis-group.id
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }
  log_config {
    enable      = true
    sample_rate = 1
  }
}

### Adding security policy for the backend - VPC restrictions don't apply to the LB
resource "google_compute_security_policy" "atlantis-demo-denyall-and-whitelist" {
  name        = "atlantis-demo-denyall-and-whitelist"
  description = "Deny all rule for accessing the backends and github whitelist IPS"
  rule {
    action   = "allow"
    priority = "0"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = local.github_hook_whitelist
      }
    }
    description = "Allow github webhooks"
  }
  rule {
    action   = "deny(403)"
    priority = "2"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["0.0.0.0/0"]
      }
    }
    description = "Deny all rule"
  }
  rule {
    action   = "deny(403)"
    priority = "2147483647"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    description = "Deny all rule"
  }
  depends_on = [google_compute_instance_group.atlantis-group]
}
