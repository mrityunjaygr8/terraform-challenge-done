variable "api_2_ip" {
  description = "The IP of the API-2 server"
}


variable "public_subnets" {
  type        = list(string)
  description = "The list of IDs of the public subnets for the Load Balaner to use"
}

variable "private_subnets" {
  type        = list(string)
  description = "The list of IDs of the priavte subnets for the instances to use"
}

variable "vpc_id" {
  description = "The VPC id of the VPC"
}

variable "az" {
  type = list(string)
}
