
resource "google_cloud_run_service" "frontend" {
  name     = "arcs-fe"
  location = var.region

  template {
    spec {
      service_account_name = "your-service-account@email.com"  # Replace with your service account name
      containers {
        image = "gcr.io/${var.project_id}/arcs-fe:${var.commit_sha}"  # Using the commit SHA for versioning
      }

      vpc_connector_name = google_vpc_access_connector.connector.name
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
  role   = "roles/run.invoker"
  member = "serviceAccount:${google_service_account.frontend.email}"
}

// Optionally, if you want to give it the Cloud Run Admin role:
resource "google_project_iam_member" "frontend-admin" {
  role   = "roles/run.admin"
  member = "serviceAccount:${google_service_account.frontend.email}"
}

resource "google_service_account_key" "frontend_key" {
  service_account_id = google_service_account.frontend.name
  public_key_type    = "TYPE_X509_PEM_FILE"
}
