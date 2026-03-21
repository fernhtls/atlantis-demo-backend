locals {
  atlantis_sa_projects = [
    "atlantis-demo-app",
  ]
}

resource "google_service_account" "atlantis-sa" {
  account_id   = "atlantis-sa"
  display_name = "Service Account for Atlantis - terraform automation"
}

resource "google_service_account_key" "atlantis-sa-key" {
  service_account_id = google_service_account.atlantis-sa.id
}

resource "google_secret_manager_secret_iam_member" "service-account-access" {
  secret_id = google_secret_manager_secret.gh-token.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.atlantis-sa.email}"
}

resource "google_project_iam_member" "atlantis-sa-owner-projects" {
  for_each = toset(local.atlantis_sa_projects)
  project  = each.key
  role     = "roles/owner"
  member   = "serviceAccount:${google_service_account.atlantis-sa.email}"
}
