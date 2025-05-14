output "mig_name" {
  value = google_compute_region_instance_group_manager.mig.name
}

output "autoscaler_name" {
  value = google_compute_autoscaler.default.name
}
