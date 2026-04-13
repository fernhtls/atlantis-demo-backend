variable "algorithm" {
  type        = string
  description = "algorithm to generate the tls key"
  default     = "RSA"
  validation {
    condition     = length(var.algorithm) > 0
    error_message = "algorithm is mandatory"
  }
}

variable "rsa_bits" {
  type        = number
  description = "rsa-bit size of the key"
  default     = 2048
  validation {
    condition     = var.rsa_bits > 0
    error_message = "rsa-bit has to be bigger than 0"
  }
  validation {
    condition     = !contains(["."], tostring(var.rsa_bits))
    error_message = "value should be an integer"
  }
}

variable "validity_period_hours" {
  type        = number
  description = "validity of the tls cert in hours"
  default     = 8760
  validation {
    condition     = var.validity_period_hours > 0
    error_message = "hours validity has to be bigger than 0"
  }
  validation {
    condition     = !contains(["."], tostring(var.validity_period_hours))
    error_message = "value should be an integer"
  }
}

variable "subject" {
  type = object({
    common_name  = string
    organization = string
  })
  description = "subject object - common_name and organization"
  default = {
    common_name  = "atlantis"
    organization = "atlantis-demo"
  }
}

variable "allowed_users" {
  type        = list(string)
  description = "list of allowed_users (only values can be server_auth and client_auth"
  default     = ["server_auth", "client_auth"]
  validation {
    condition     = alltrue([for au in var.allowed_users : contains(["server_auth", "client_auth"], au)])
    error_message = "must contain server_auth and / or client_auth"
  }
}

variable "ip_addresses" {
  type        = list(string)
  description = "list of ip addresses to add as part of the self-signed cert"
  validation {
    condition     = can(length(var.ip_addresses) > 0)
    error_message = "at least one ip has to be informed"
  }
  validation {
    condition     = alltrue([for ip in var.ip_addresses : can(regex("^([0-9]{1,3}\\.){3}$", ip))])
    error_message = "wrong mask for ip"
  }
}
