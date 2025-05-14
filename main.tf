provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# VPC
resource "google_compute_network" "vpc_network" {
  name = "mig-vpc"
}

# Subnet
resource "google_compute_subnetwork" "subnet" {
  name          = "mig-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.region
  network       = google_compute_network.vpc_network.id
}

# Firewall rule to allow SSH
resource "google_compute_firewall" "allow-ssh" {
  name    = "allow-ssh"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
}

# Instance template
resource "google_compute_instance_template" "default" {
  name         = "mig-template"
  machine_type = "e2-medium"

  disk {
    source_image = "debian-cloud/debian-11"
    auto_delete  = true
    boot         = true
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.id

    access_config {
      # Ephemeral public IP
    }
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    apt-get update
    apt-get install -y apache2
    systemctl start apache2
    echo "Hello from MIG instance" > /var/www/html/index.html
  EOT
}

# Health check
resource "google_compute_health_check" "default" {
  name               = "http-health-check"
  check_interval_sec = 10
  timeout_sec        = 5
  healthy_threshold  = 2
  unhealthy_threshold = 3

  http_health_check {
    port = 80
  }
}

# Managed instance group
resource "google_compute_region_instance_group_manager" "mig" {
  name               = "regional-mig"
  base_instance_name = "mig-instance"
  region             = var.region
  version {
    instance_template = google_compute_instance_template.default.self_link
  }

  target_size = 2

  named_port {
    name = "http"
    port = 80
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.default.self_link
    initial_delay_sec = 60
  }

  distribution_policy_zones = [
    "${var.region}-a",
    "${var.region}-b"
  ]
}
