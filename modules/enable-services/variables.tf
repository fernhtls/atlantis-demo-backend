variable "gcp_services" {
  type        = list(string)
  description = "List of services to be enabled"
  validation {
    condition     = can(length(var.gcp_services) > 0)
    error_message = "no services to enable"
  }
}
