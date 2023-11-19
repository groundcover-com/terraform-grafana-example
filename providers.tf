terraform {
  required_providers {
    grafana = {
      source = "grafana/grafana"
      version = "2.5.0"
    }
  }
}

provider "grafana" {
  url  = var.groundcover_url
  auth = var.service_account
}

