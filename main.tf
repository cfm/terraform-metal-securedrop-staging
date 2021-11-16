terraform {
  required_providers {
    metal = {
      source = "equinix/metal"
    }
  }
}

variable "auth_token" {
  sensitive = true
}

variable "metro" {}

variable "plan" {
  default = "c3.small.x86"
}

variable "project" {}

provider "metal" {
  auth_token = var.auth_token
}

data "metal_project" "project" {
  name = var.project
}

resource "metal_device" "sd-staging" {
  hostname         = "sd-staging"
  plan             = var.plan
  metro            = var.metro
  operating_system = "debian_10"
  billing_cycle    = "hourly"
  project_id       = data.metal_project.project.id
  user_data        = file("${path.module}/user_data.yml")
}
