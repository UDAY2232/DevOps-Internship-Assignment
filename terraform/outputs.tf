output "api_public_ip" {
  description = "Public IP of the API gateway"
  value       = google_compute_address.api_static_ip.address
}

output "api_private_ip" {
  value = google_compute_instance.api.network_interface[0].network_ip
}

output "python_worker_ip" {
  value = google_compute_instance.python_worker.network_interface[0].network_ip
}

output "ts_worker_ip" {
  value = google_compute_instance.ts_worker.network_interface[0].network_ip
}

output "model_worker_ip" {
  value = google_compute_instance.model_worker.network_interface[0].network_ip
}
