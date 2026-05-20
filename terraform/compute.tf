// Reserve a static external IP for API gateway
resource "google_compute_address" "api_static_ip" {
  name   = "api-static-ip"
  region = var.region
}

// Common metadata startup to fetch and run setup script from repo
locals {
  common_startup = <<-EOT
    #!/bin/bash
    set -xe
    apt-get update
    apt-get install -y git curl ca-certificates
    # Clone the repo and checkout branch
    if [ -z "${repo_url}" ]; then
      echo "Repository URL not set in instance metadata; aborting"
      exit 1
    fi
    git clone --depth 1 -b ${repo_branch} ${repo_url} /opt/devops-assignment || true
    cd /opt/devops-assignment || true
    chmod +x scripts/*.sh || true
    # run instance-specific setup script
    if [ -f "$SETUP_SCRIPT" ]; then
      bash "$SETUP_SCRIPT"
    fi
  EOT
}

resource "google_compute_instance" "api" {
  name         = "api-gateway"
  machine_type = var.api_machine_type

  tags = ["api-gateway"]

  boot_disk {
    initialize_params {
      image = "ubuntu-2204-lts"
      size  = 20
      type  = "pd-standard"
    }
  }

  network_interface {
    network    = google_compute_network.vpc.id
    subnetwork = google_compute_subnetwork.private.id
    network_ip = var.api_private_ip
    access_config {
      // This gives the API gateway a public IP
    }
  }

  metadata = {
    repo_url     = var.repo_url
    repo_branch  = var.repo_branch
    SETUP_SCRIPT = "/opt/devops-assignment/scripts/setup-api.sh"
    // expose private worker IPs to API instance for configuration
    PYTHON_WORKER_IP = var.python_worker_ip
    TS_WORKER_IP     = var.ts_worker_ip
    MODEL_WORKER_IP  = var.model_worker_ip
  }

  metadata_startup_script = replace(local.common_startup, "${repo_url}", var.repo_url)
}

resource "google_compute_instance" "python_worker" {
  name         = "python-worker"
  machine_type = var.worker_machine_type

  boot_disk {
    initialize_params {
      image = "ubuntu-2204-lts"
      size  = 10
      type  = "pd-standard"
    }
  }

  network_interface {
    network    = google_compute_network.vpc.id
    subnetwork = google_compute_subnetwork.private.id
    network_ip = var.python_worker_ip
  }

  metadata = {
    repo_url     = var.repo_url
    repo_branch  = var.repo_branch
    SETUP_SCRIPT = "/opt/devops-assignment/scripts/setup-python-worker.sh"
    TS_WORKER_IP = var.ts_worker_ip
    MODEL_WORKER_IP = var.model_worker_ip
  }

  metadata_startup_script = replace(local.common_startup, "${repo_url}", var.repo_url)
}

resource "google_compute_instance" "ts_worker" {
  name         = "ts-worker"
  machine_type = var.worker_machine_type

  boot_disk {
    initialize_params {
      image = "ubuntu-2204-lts"
      size  = 10
      type  = "pd-standard"
    }
  }

  network_interface {
    network    = google_compute_network.vpc.id
    subnetwork = google_compute_subnetwork.private.id
    network_ip = var.ts_worker_ip
  }

  metadata = {
    repo_url     = var.repo_url
    repo_branch  = var.repo_branch
    SETUP_SCRIPT = "/opt/devops-assignment/scripts/setup-ts-worker.sh"
    PYTHON_WORKER_IP = var.python_worker_ip
    MODEL_WORKER_IP = var.model_worker_ip
  }

  metadata_startup_script = replace(local.common_startup, "${repo_url}", var.repo_url)
}

resource "google_compute_instance" "model_worker" {
  name         = "model-worker"
  machine_type = var.worker_machine_type

  boot_disk {
    initialize_params {
      image = "ubuntu-2204-lts"
      size  = 50
      type  = "pd-standard"
    }
  }

  network_interface {
    network    = google_compute_network.vpc.id
    subnetwork = google_compute_subnetwork.private.id
    network_ip = var.model_worker_ip
  }

  metadata = {
    repo_url     = var.repo_url
    repo_branch  = var.repo_branch
    SETUP_SCRIPT = "/opt/devops-assignment/scripts/setup-model-worker.sh"
    PYTHON_WORKER_IP = var.python_worker_ip
    TS_WORKER_IP     = var.ts_worker_ip
  }

  metadata_startup_script = replace(local.common_startup, "${repo_url}", var.repo_url)
}
