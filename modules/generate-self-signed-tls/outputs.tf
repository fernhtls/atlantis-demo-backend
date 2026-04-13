output "cert_pem" {
  value       = tls_self_signed_cert.self-signe-cert.cert_pem
  sensitive   = true
  description = "cert pem for the self-signed cert"
}

output "private_key_pem" {
  value       = tls_private_key.private-key.private_key_pem
  sensitive   = true
  description = "private key pem"
}
