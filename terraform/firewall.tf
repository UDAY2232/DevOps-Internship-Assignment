// Allow internal communication within the VPC subnet
resource "google_compute_firewall" "allow-internal" {
  name    = "allow-internal-devops"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  source_ranges = [var.subnet_cidr]
  direction     = "INGRESS"
  description   = "Allow all internal traffic within subnet for RPC and management"
}

// Allow HTTP(S) only to API gateway (tagged)
resource "google_compute_firewall" "api-http" {
  name    = "allow-api-http"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "8080"]
  }

  target_tags   = ["api-gateway"]
  source_ranges = ["0.0.0.0/0"]
  description   = "Allow public HTTP(S) to API gateway only"
}

// Allow SSH only from admin CIDR to API gateway
resource "google_compute_firewall" "ssh-api" {
  name    = "allow-ssh-api"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  target_tags   = ["api-gateway"]
  source_ranges = [var.ssh_cidr]
  description   = "Restrict SSH to API gateway from admin CIDR only"
}
