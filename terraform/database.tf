# Use locals for handling certain values
locals {
  db_password     = data.google_secret_manager_secret_version.db_password.secret_data
}
resource "google_sql_user" "default" {
  name     = "arcs_user"
  instance = google_sql_database_instance.default.name
  password = local.db_password
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
      authorized_networks {
        name  = "My network"
        value = "73.15.169.24" # Your public IP
      }
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