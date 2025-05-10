resource "google_compute_network" "vpc" {
  name                    = "etl-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = "etl-subnet"
  network       = google_compute_network.vpc.name
  region        = var.region
  ip_cidr_range = "10.10.0.0/24"
}