resource "google_cloud_run_service" "frontend" {
  name     = "arcs-fe"
  location = var.region

  template {
    spec {
      service_account_name = google_service_account.frontend.email
      containers {
        image = "gcr.io/${var.project_id}/arcs-fe:${var.commit_sha}"
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

resource "google_service_account" "frontend" {
  account_id   = "frontend-service-account"
  display_name = "Service account for the Cloud Run frontend service"
}

resource "google_project_iam_member" "frontend-invoker" {
  project = var.project_id
  role   = "roles/run.invoker"
  member = "serviceAccount:${google_service_account.frontend.email}"
}

resource "google_project_iam_member" "frontend-admin" {
  project = var.project_id
  role   = "roles/run.admin"
  member = "serviceAccount:${google_service_account.frontend.email}"
}

resource "google_service_account_key" "frontend_key" {
  service_account_id = google_service_account.frontend.name
  public_key_type    = "TYPE_X509_PEM_FILE"
}
