# terraform-grafana-example
How to provision groundcover's grafana alerts and dashboards using terraform

## Getting started

1. Generate a service account token using [groundcover cli](https://github.com/groundcover-com/cli) - ```groundcover auth generate-service-account-token```

2. Change directory to `terraform-grafana-example` - ```cd terraform-grafana-example```

3. Apply the Terraform plan - ```terraform apply -var cluster_name={Your cluster name} -var service_account={Your generated service account token}```

