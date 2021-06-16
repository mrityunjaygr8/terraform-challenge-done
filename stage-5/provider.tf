terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.45.0"
    }

    google = {
      source  = "hashicorp/google"
      version = "3.72.0"
    }
  }
  backend "s3" {
    bucket = "egt-tf-state"
    key    = "state"
    region = "us-east-1"
  }
}

provider "aws" {
  # Configuration options
  region = "us-east-1"
}

provider "google" {
  # Configuration options
  project = "windy-city-316109"
  region  = "us-central1"
  zone    = "us-central1-c"
}
