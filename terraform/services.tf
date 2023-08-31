
resource "google_project_service" "compute_api" {
  service = "compute.googleapis.com"
}
resource "google_project_service" "vpc_api" {
  service = "compute.googleapis.com"  # The VPC is part of the Compute API
}
resource "google_project_service" "cloudbuild_api" {
  service = "cloudbuild.googleapis.com"
}
resource "google_project_service" "secret_manager_api" {
  service = "secretmanager.googleapis.com"
}
resource "google_project_service" "cloud_run_api" {
  service = "run.googleapis.com"
}
resource "google_project_service" "service_networking_api" {
  service = "servicenetworking.googleapis.com"
}
resource "google_project_service" "cloudsql_admin_api" {
  service = "sqladmin.googleapis.com"
}
