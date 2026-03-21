### LB setup and proxy

## PS: names are using atlantis as the initial setup was only for atlantis

resource "google_compute_global_address" "atlantis-lb-global-address" {
  name       = "atlantis-lb-global-address"
  ip_version = "IPV4"
}

### Generating a self-signed cert - managed certs only work with domains
resource "tls_private_key" "atlantis-key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "atlantis-demo-ssl-cert" {
  private_key_pem       = tls_private_key.atlantis-key.private_key_pem
  validity_period_hours = 8760 # 1 year
  subject {
    common_name  = "atlantis"
    organization = "atlantis-demo"
  }
  allowed_uses = ["server_auth", "client_auth"]
  ip_addresses = [google_compute_global_address.atlantis-lb-global-address.address]
}

resource "google_compute_ssl_certificate" "atlantis-compute-ssl-cert" {
  name        = "atlantis-compute-ssl-cert"
  private_key = tls_private_key.atlantis-key.private_key_pem
  certificate = tls_self_signed_cert.atlantis-demo-ssl-cert.cert_pem
}

resource "google_compute_url_map" "atlantis_url_map_https" {
  name = "atlantis-url-map-https"
  # keeping atlantis as default for now
  default_service = google_compute_backend_service.atlantis-backend-service.id
}

resource "google_compute_target_https_proxy" "atlantis_https_lb_proxy" {
  provider = google-beta
  name     = "atlantis-https-lb-proxy"
  url_map  = google_compute_url_map.atlantis_url_map_https.id
  ssl_certificates = [
    google_compute_ssl_certificate.atlantis-compute-ssl-cert.id
  ]
}

resource "google_compute_global_forwarding_rule" "atlantis-lb-fw-rule" {
  name                  = "atlantis-lb-fw-rule"
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = "443"
  target                = google_compute_target_https_proxy.atlantis_https_lb_proxy.id
  ip_address            = google_compute_global_address.atlantis-lb-global-address.id
}

