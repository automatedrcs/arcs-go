variable "project_id" {
  description = "The ID of the project in which to provision resources."
  type        = string
}

variable "region" {
  description = "The GCP region."
  type        = string
  default     = "us-central1"
}

variable "cluster_name" {
  description = "The name of the GKE cluster."
  type        = string
}

variable "database_name" {
  description = "The name of the SQL database."
  type        = string
  default     = "arcs_db"
}

variable "database_user" {
  description = "The user of the SQL database."
  type        = string
  default     = "arcs_user"
}