locals {
  alert_groups_file = yamldecode(file("assets/exported_alert_rules.yaml"))
}

data "grafana_data_source" "prometheus" {
  name = format("Prometheus@%s", var.cluster_name)
}

resource "grafana_folder" "introduction" {
  title = "groundcover introduction"
}

resource "grafana_dashboard" "kubernetes_resources" {
  config_json = file("assets/kubernetes_resource_dashboard.json")
  folder = grafana_folder.introduction.id
}

resource "grafana_rule_group" "alertrule" {
  for_each = { for group in local.alert_groups_file.groups : group.name => group }
  org_id = data.grafana_data_source.prometheus.org_id
  name = each.value.name
  folder_uid = grafana_folder.introduction.uid
  interval_seconds = 60

  dynamic "rule" {
    for_each = each.value.rules

    content {
      name = rule.value.title 
      for = rule.value.for
      condition = rule.value.condition
      no_data_state = rule.value.noDataState
      exec_err_state = rule.value.execErrState
      is_paused = rule.value.isPaused
      labels = try(rule.value.labels, null)
      annotations = try(rule.value.annotations, null)

      dynamic "data" {
        for_each = rule.value.data
        iterator = rule_data
        content {
          datasource_uid =  startswith(rule_data.value.datasourceUid, "__") ? rule_data.value.datasourceUid  : data.grafana_data_source.prometheus.uid
          ref_id = rule_data.value.refId
          relative_time_range {
            from = try(rule_data.value.relativeTimeRange.from,0)
            to = try(rule_data.value.relativeTimeRange.to,0)
          }
          model = jsonencode(merge(rule_data.value.model, {datasource = { uid = startswith(rule_data.value.datasourceUid, "__") ? rule_data.value.datasourceUid : data.grafana_data_source.prometheus.uid}}))
        }
      }
    }
  }
}
