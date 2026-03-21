data "local_sensitive_file" "gh-token" {
  filename = "secrets/token.txt"
}

resource "google_secret_manager_secret" "gh-token" {
  secret_id = "gh-token"
  replication {
    auto {}
  }
  deletion_protection = false
}

# Create a new version of the secret
resource "google_secret_manager_secret_version" "gh-token-version" {
  secret      = google_secret_manager_secret.gh-token.id
  secret_data = data.local_sensitive_file.gh-token.content
}

data "local_sensitive_file" "webhook-token" {
  filename = "secrets/webhook_token.txt"
}

resource "google_secret_manager_secret" "webhook-token" {
  secret_id = "webhook-token"
  replication {
    auto {}
  }
  deletion_protection = false
}

# Create a new version of the secret
resource "google_secret_manager_secret_version" "webhook-token-version" {
  secret      = google_secret_manager_secret.webhook-token.id
  secret_data = data.local_sensitive_file.webhook-token.content
}
