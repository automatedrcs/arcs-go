data "google_client_config" "default" {
  depends_on = [google_container_cluster.primary]
}

provider "kubernetes" {
  host                   = "https://${google_container_cluster.primary.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.primary.master_auth[0].cluster_ca_certificate)
}

resource "google_container_cluster" "primary" {
  name               = var.cluster_name
  location           = var.region
  initial_node_count = 1
  network            = google_compute_network.custom_vpc.name
  subnetwork         = google_compute_subnetwork.custom_subnet.name

  remove_default_node_pool = true

  ip_allocation_policy {
      # These can be left empty for GKE to auto-assign
      cluster_secondary_range_name  = ""
      services_secondary_range_name = ""
  }

  private_cluster_config {
    enable_private_endpoint = false
    enable_private_nodes    = true
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }

  # Enable master authorized networks
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "73.15.169.24/32"  # Your public IP
      display_name = "My network"
    }
  }


  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"
}

resource "google_container_node_pool" "primary_nodes" {
  name       = "${var.cluster_name}-node-pool"
  location   = var.region
  cluster    = google_container_cluster.primary.name
  node_count = 1  # We set the node_count to 1 since we want one node in each zone

  node_locations = [   # Specify the zones where you want your nodes
    "${var.region}-a",
    "${var.region}-b",
    "${var.region}-c"
  ]

  node_config {
    preemptible  = false
    machine_type = "n1-standard-1"
    disk_size_gb = 30
    metadata = {
      disable-legacy-endpoints = "true"
    }
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
}

resource "google_cloudbuild_trigger" "go_api" {
  description = "Trigger for the Go-based web API"

  github {
    owner = "automatedrcs"
    name  = "arcs-go"

    push {
      branch = "^main$"
    }
  }
  
  filename = "cloudbuild.yaml"

  substitutions = {
    _GKE_ZONE         = "us-central1"
    _GKE_CLUSTER_NAME = "arcs-go-cluster"
  }
}

resource "google_service_account" "arcs_go" {
  account_id   = "arcs-go-service-account"
  display_name = "Service account for the arcs-go backend service"
}

resource "google_project_iam_member" "arcs_go_gke_developer" {
  project = var.project_id
  role   = "roles/container.developer"
  member = "serviceAccount:${google_service_account.arcs_go.email}"
}

resource "kubernetes_namespace" "arcs_go_namespace" {
  metadata {
    name = "arcs-go-namespace"
  }
}

resource "kubernetes_service_account" "arcs_go_k8s_sa" {
  metadata {
    name      = "arcs-go-k8s-service-account"
    namespace = kubernetes_namespace.arcs_go_namespace.metadata[0].name
    annotations = {
      "iam.gke.io/gcp-service-account" = google_service_account.arcs_go.email
    }
  }
}

resource "kubernetes_deployment" "api_deployment" {
  metadata {
    name      = "api-deployment"
    namespace = kubernetes_namespace.arcs_go_namespace.metadata[0].name
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "api"
      }
    }

    template {
      metadata {
        labels = {
          app = "api"
        }
      }

      spec {
        container {
          name  = "api"
          image = "gcr.io/${var.project_id}/arcs-go:${data.github_commit.this.sha}"

          port {
            container_port = 8080
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "api_service" {
  metadata {
    name      = "api-service"
    namespace = kubernetes_namespace.arcs_go_namespace.metadata[0].name
  }

  spec {
    selector = {
      app = "api"
    }

    port {
      port        = 80
      target_port = 8080
    }

    type = "LoadBalancer"
  }
}
