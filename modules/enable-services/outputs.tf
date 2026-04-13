output "services_enabled" {
  value       = google_project_service.service
  description = "terraform resource for services enabled (list / set)"
}

output "set-services-enabled" {
  value       = var.gcp_services
  description = "list of services enabled"
}

