provider "google" {
  project = var.project_id
  region  = var.region
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
    enable_private_endpoint = true
    enable_private_nodes    = true
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }

  # Enable master authorized networks
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = "192.168.0.0/24"  # Replace with your network CIDR or specific IPs that should have access
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

resource "google_compute_network" "custom_vpc" {
  name                    = "arcs-vpc"
  auto_create_subnetworks = false
  description             = "Custom VPC for our infrastructure"
}

resource "google_compute_subnetwork" "custom_subnet" {
  name          = "arcs-subnet"
  ip_cidr_range = "10.0.0.0/16"
  region        = var.region
  network       = google_compute_network.custom_vpc.name
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.custom_vpc.self_link
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_range.name]
}

resource "google_compute_global_address" "private_range" {
  name          = "private-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.custom_vpc.self_link
}

resource "google_container_node_pool" "primary_nodes" {
  name       = "${var.cluster_name}-node-pool"
  location   = var.region
  cluster    = google_container_cluster.primary.name
  node_count = 3

  node_config {
    preemptible  = false
    machine_type = "n1-standard-1"
    disk_size_gb = 30
    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
}

resource "google_sql_database_instance" "default" {
  name             = "arcs-sql-instance"
  database_version = "POSTGRES_13"
  depends_on = [google_service_networking_connection.private_vpc_connection]
 
  settings {
    tier = "db-g1-small"
    
    ip_configuration {
      ipv4_enabled    = true
      private_network = google_compute_network.custom_vpc.self_link
    }

    backup_configuration {
      enabled = true
    }

    location_preference {
      zone = "us-central1-a" # or another specific zone
    }
  }
}

resource "google_sql_database" "default" {
  name     = "arcs_db"
  instance = google_sql_database_instance.default.name
  collation = "en_US.UTF8"
}

data "google_secret_manager_secret_version" "db_password" {
  secret  = "arcs-db-password"
  version = "latest"
}

resource "google_sql_user" "default" {
  name     = "arcs_user"
  instance = google_sql_database_instance.default.name
  password = data.google_secret_manager_secret_version.db_password.secret_data
}
