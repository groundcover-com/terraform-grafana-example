variable cluster_name {
  type        = string
  description = "cluster name"
}

variable service_account {
    type = string
    description = "generated service account"
}

variable groundcover_url {
  type = string
  default = "https://app.groundcover.com/grafana"
  description = "groundcover url"
}