provider "google" {
  credentials = file("<PATH_TO_YOUR_SERVICE_ACCOUNT_JSON>")
  project     = "<YOUR_GCP_PROJECT_ID>"
  region      = "us-central1"
}

resource "google_container_cluster" "primary" {
  name     = "gke-cluster"
  location = "us-central1-a"

  remove_default_node_pool = true
  initial_node_count       = 1

  master_auth {
    username = ""
    password = ""

    client_certificate_config {
      issue_client_certificate = false
    }
  }
}

resource "google_container_node_pool" "primary_nodes" {
  name       = "gke-node-pool"
  location   = "us-central1-a"
  cluster    = google_container_cluster.primary.name
  node_count = 1

  node_config {
    preemptible  = false
    machine_type = "n1-standard-1"
  }
}
