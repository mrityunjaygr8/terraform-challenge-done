variable "gcp_image_name" {
  description = "name of the image to be used for creating the VM"
}

variable "gcp_machine_size" {
  description = "The size of the VM to be created"
  default     = "e2-micro"
}
