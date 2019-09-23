#####
# Deployment
#####

#####
# Service
#####
resource "kubernetes_service" "this" {
  metadata {
    name      = var.service_name == "" ? "azure-metrics-exporter" : var.service_name
    namespace = var.namespace
    annotations = merge(
      {
        "prometheus.io/scrape" = "true"
      },
      var.annotations,
      var.service_annotations
    )
    labels = merge(
      {
        "app.kubernetes.io/name"       = "azure-metrics-exporter"
        "app.kubernetes.io/instance"   = var.service_name == "" ? var.namespace : var.service_name
        "app.kubernetes.io/version"    = ""
        "app.kubernetes.io/component"  = "exporter"
        "app.kubernetes.io/part-of"    = "prometheusplusplus"
        "app.kubernetes.io/managed-by" = "terraform"
      },
      var.labels,
      var.service_labels
    )
  }
}
#####
# ConfigMap
#####

#####
# Secret
#####
