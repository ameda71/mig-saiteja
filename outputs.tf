output "instance_group_manager_name" {
  value = google_compute_region_instance_group_manager.mig.name
}

output "template_name" {
  value = google_compute_instance_template.default.name
}
