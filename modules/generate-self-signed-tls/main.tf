resource "tls_private_key" "private-key" {
  algorithm = var.algorithm
  rsa_bits  = var.rsa_bits
}

resource "tls_self_signed_cert" "self-signe-cert" {
  private_key_pem       = tls_private_key.private-key.private_key_pem
  validity_period_hours = var.validity_period_hours
  subject {
    common_name  = var.subject.common_name
    organization = var.subject.organization
  }
  allowed_uses = var.allowed_users
  ip_addresses = var.ip_addresses
}
