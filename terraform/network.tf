# Use locals for handling certain values
locals {
  vpn_shared_key  = data.google_secret_manager_secret_version.vpn_shared_secret.secret_data
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

resource "google_compute_vpn_gateway" "gateway" {
  name    = "vpn-gateway"
  region  = var.region
  network = google_compute_network.custom_vpc.name
}

resource "google_compute_forwarding_rule" "udp_4500_rule" {
  name        = "vpn-forwarding-rule-udp4500"
  description = "Forwarding rule for VPN on UDP 4500"
  region      = "us-central1" # or your desired region
  ip_protocol = "UDP"
  port_range  = "4500"
  target      = google_compute_vpn_gateway.gateway.self_link
  load_balancing_scheme = "EXTERNAL"
  ip_address             = google_compute_address.vpn.address
}

resource "google_compute_forwarding_rule" "fr" {
  name        = "vpn-forwarding-rule"
  region      = var.region
  ip_protocol = "ESP"
  ip_address  = google_compute_address.vpn.address
  target      = google_compute_vpn_gateway.gateway.self_link
}

data "google_secret_manager_secret_version" "vpn_shared_secret" {
  secret  = "IKE-Pre-shared-key"
  version = "latest"
}

resource "google_compute_vpn_tunnel" "tunnel" {
  name               = "vpn-tunnel"
  region             = var.region
  target_vpn_gateway = google_compute_vpn_gateway.gateway.name
  shared_secret      = local.vpn_shared_key
  peer_ip            = "73.15.169.24"
  ike_version        = 2
  
  local_traffic_selector  = ["10.0.0.0/16"]
  remote_traffic_selector = ["192.168.0.0/24"]
}


resource "google_compute_address" "vpn" {
  name   = "vpn-address"
  region = var.region
}

resource "google_vpc_access_connector" "connector" {
  name          = "vpc-connector"
  region        = var.region
  network       = google_compute_network.custom_vpc.name
  ip_cidr_range = "10.8.0.0/28" 
}

resource "google_compute_forwarding_rule" "vpn_gateway_rule" {
  name                   = "vpn-gateway-rule"
  region                 = var.region
  target                 = google_compute_vpn_gateway.gateway.self_link
  ip_protocol            = "UDP"
  port_range             = "500-500"
  load_balancing_scheme  = "EXTERNAL"
  network_tier           = "PREMIUM"
  description            = "Forwarding rule for VPN Gateway on UDP:500"
  ip_address             = google_compute_address.vpn.address
}

