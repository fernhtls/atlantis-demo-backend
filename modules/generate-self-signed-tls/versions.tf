terraform {
  required_version = ">= 1.11.5"
  required_providers {
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.2.1"
    }
  }
}
