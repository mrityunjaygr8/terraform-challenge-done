output "api_2_IP" {
  description = "The IP of the API-2 machine"
  value       = google_compute_instance.api2.network_interface[0].access_config[0].nat_ip
}
