locals {
  alert_groups_file = yamldecode(file("assets/exported_alert_rules.yaml"))

  duration_multiplier = {
    "s" = 1
    "m" = 60
    "h" = 60 * 60
    "d" = 60 * 60 * 24
  }
}

data "grafana_data_source" "prometheus" {
  name = format("Prometheus@%s", var.cluster_name)
}

resource "grafana_folder" "introduction" {
  title = "groundcover introduction"
}

resource "grafana_dashboard" "kubernetes_resources" {
  folder      = grafana_folder.introduction.id
  config_json = file("assets/kubernetes_resource_dashboard.json")
}

resource "grafana_rule_group" "alertrule" {
  for_each = {
    for group in local.alert_groups_file.groups : group.name => group
  }

  name       = each.value.name
  folder_uid = grafana_folder.introduction.uid
  org_id     = data.grafana_data_source.prometheus.org_id

  interval_seconds = sum(
    [
      for duration in regexall("([0-9]+)([a-z]+)", each.value.interval) : duration[0] * local.duration_multiplier[duration[1]]
    ]
  )

  dynamic "rule" {
    for_each = each.value.rules

    content {
      for            = rule.value.for
      name           = rule.value.title
      is_paused      = rule.value.isPaused
      condition      = rule.value.condition
      no_data_state  = rule.value.noDataState
      exec_err_state = rule.value.execErrState
      labels         = try(rule.value.labels, null)
      annotations    = try(rule.value.annotations, null)

      dynamic "data" {
        iterator = rule_data
        for_each = rule.value.data

        content {
          ref_id         = rule_data.value.refId
          datasource_uid = startswith(rule_data.value.datasourceUid, "__") ? rule_data.value.datasourceUid : data.grafana_data_source.prometheus.uid

          model = jsonencode(
            merge(rule_data.value.model,
              {
                datasource = {
                  uid = startswith(rule_data.value.datasourceUid, "__") ? rule_data.value.datasourceUid : data.grafana_data_source.prometheus.uid
                }
              }
            )
          )

          relative_time_range {
            to   = try(rule_data.value.relativeTimeRange.to, 0)
            from = try(rule_data.value.relativeTimeRange.from, 0)
          }
        }
      }
    }
  }
}
