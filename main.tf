provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

resource "google_compute_instance_template" "default" {
  name         = "instance-template"
  machine_type = "e2-micro"

  disk {
  boot       = true
  auto_delete = true

  initialize_params {
    image = "debian-11"
  }
}


  network_interface {
    network = "default"
    access_config {}
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    apt-get update
    apt-get install -y nginx
  EOT
}

resource "google_compute_region_instance_group_manager" "mig" {
  name               = "my-mig"
  base_instance_name = "mig-instance"
  region             = var.region
  version {
    instance_template = google_compute_instance_template.default.self_link
  }

  target_size = 2

  auto_healing_policies {
    health_check      = google_compute_health_check.default.self_link
    initial_delay_sec = 60
  }
}

resource "google_compute_health_check" "default" {
  name = "basic-http-health-check"
  http_health_check {
    port = 80
  }
  check_interval_sec  = 5
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 2
}

resource "google_compute_autoscaler" "default" {
  name   = "mig-autoscaler"
  region = var.region
  target = google_compute_region_instance_group_manager.mig.self_link

  autoscaling_policy {
    min_replicas    = 2
    max_replicas    = 5

    cpu_utilization {
      target = 0.6
    }

    cooldown_period = 60
  }
}
