variable "az" {
  type = list(string)
}

variable "gcp_image_name" {

}

module "network" {
  source = "./modules/network/aws"
  az     = var.az
}

module "api_2" {
  source         = "./modules/api-2"
  gcp_image_name = var.gcp_image_name
}

module "api_1" {
  source          = "./modules/api-1"
  public_subnets  = module.network.public_subnet
  private_subnets = module.network.private_subnet
  vpc_id          = module.network.vpc_id
  api_2_ip        = module.api_2.api_2_IP
  az              = var.az
}

output "elb_dns_name" {
  value = module.api_1.elb-dns
}
