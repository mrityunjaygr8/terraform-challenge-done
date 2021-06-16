resource "google_compute_instance" "api2" {
  name         = "api-2"
  machine_type = var.gcp_machine_size

  tags = ["api-2"]

  boot_disk {
    initialize_params {
      image = var.gcp_image_name
    }
  }

  network_interface {
    network = "default"

    access_config {

    }
  }
}
