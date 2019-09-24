#####
# Locals
#####

locals {
  default_configuration = {
    configuration = {
      active_directory_authority_url = "https://login.microsoftonline.com/"
      resource_manager_url : "https://management.azure.com/"
    }
  }
  configuration       = yamlencode(merge(local.default_configuration, var.configuration))
  confd_configuration = <<EOH
[template]
src = "azure.yml.tmpl"
dest = "/data/azure.yml"
mode = "0644"
keys = ["/configuration"]
EOH
  confd_template      = <<EOT
credentials:
  subscription_id: {{ getenv "subscription_id" }}
  client_id: {{ getenv "client_id" }}
  client_secret: {{ getenv "client_secret" }}
  tenant_id: {{ getenv "tenant_id" }}
{{ getv "/configuration" }}
EOT
}

#####
# Randoms
#####

resource "random_string" "selector" {
  special = false
  upper   = false
  number  = false
  length  = 8
}

#####
# Deployment
#####

resource "kubernetes_deployment" "this" {
  metadata {
    name      = var.deployment_name
    namespace = var.namespace
    annotations = merge(
      var.annotations,
      var.deployment_annotations
    )
    labels = merge(
      {
        "app.kubernetes.io/name"       = "azure-metrics-exporter"
        "app.kubernetes.io/instance"   = var.deployment_name
        "app.kubernetes.io/version"    = "0.6.0"
        "app.kubernetes.io/component"  = "exporter"
        "app.kubernetes.io/part-of"    = "monitoring"
        "app.kubernetes.io/managed-by" = "terraform"
      },
      var.labels,
      var.deployment_labels
    )
  }

  spec {
    replicas = var.replicas
    selector {
      match_labels = {
        app = random_string.selector.result
      }
    }
    template {
      metadata {
        annotations = merge(
          var.annotations,
          var.deployment_annotations
        )
        labels = merge(
          {
            "app.kubernetes.io/name"       = "azure-metrics-exporter"
            "app.kubernetes.io/instance"   = var.deployment_name
            "app.kubernetes.io/version"    = "0.6.0"
            "app.kubernetes.io/component"  = "exporter"
            "app.kubernetes.io/part-of"    = "monitoring"
            "app.kubernetes.io/managed-by" = "terraform"
            app                            = random_string.selector.result
          },
          var.labels,
          var.deployment_labels
        )
      }
      spec {
        volume {
          name = "config-volume"
          empty_dir {}
        }

        volume {
          name = "confd-templates"
          config_map {
            name = kubernetes_config_map.this.metadata.0.name
            items {
              key  = "azure.yaml.tmpl"
              path = "azure.yaml.tmpl"
            }
          }
        }

        volume {
          name = "confd-config"
          config_map {
            name = kubernetes_config_map.this.metadata.0.name
            items {
              key  = "azure.toml"
              path = "azure.toml"
            }
          }
        }

        volume {
          name = "confd-sources"
          config_map {
            name = kubernetes_config_map.this.metadata.0.name
            items {
              key  = "configuration.yaml"
              path = "configuration.yaml"
            }
          }
        }

        init_container {
          name  = "confd"
          image = "fxinnovation/confd:0.1.0"
          args = [
            "-onetime",
            "-backend=file",
            "-file=/etc/confd/sources/configuration.yaml"
          ]

          volume_mount {
            name       = "config-volume"
            mount_path = "/data"
          }

          volume_mount {
            name       = "confd-config"
            mount_path = "/etc/confd/conf.d"
          }

          volume_mount {
            name       = "confd-sources"
            mount_path = "/etc/confd/sources"
          }

          volume_mount {
            name       = "confd-templates"
            mount_path = "/etc/confd/templates"
          }

          env {
            name = "subscription_id"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.this.metadata.0.name
                key  = "subscription_id"
              }
            }
          }

          env {
            name = "client_id"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.this.metadata.0.name
                key  = "client_id"
              }
            }
          }

          env {
            name = "tenant_id"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.this.metadata.0.name
                key  = "tenant_id"
              }
            }
          }

          env {
            name = "client_secret"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.this.metadata.0.name
                key  = "client_secret"
              }
            }
          }
        }

        container {
          name              = "azure-metrics-exporter"
          image             = "fxinnovation/azure_metrics_exporter:0.6.0"
          image_pull_policy = var.image_pull_policy

          volume_mount {
            name       = "config-volume"
            mount_path = "/opt/azure_metrics_exporter/conf"
          }

          port {
            name           = "http"
            container_port = 9276
            protocol       = "TCP"
          }

          resources {
            requests {
              memory = "64Mi"
              cpu    = "50m"
            }
            limits {
              memory = "128Mi"
              cpu    = "100m"
            }
          }
        }
      }
    }
  }
}

#####
# Service
#####

resource "kubernetes_service" "this" {
  metadata {
    name      = var.service_name
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
        "app.kubernetes.io/instance"   = var.service_name
        "app.kubernetes.io/version"    = "0.6.0"
        "app.kubernetes.io/component"  = "exporter"
        "app.kubernetes.io/part-of"    = "monitoring"
        "app.kubernetes.io/managed-by" = "terraform"
      },
      var.labels,
      var.service_labels
    )
  }

  spec {
    selector = {
      app = random_string.selector.result
    }
    type = "ClusterIP"
    port {
      port        = var.port
      target_port = "http"
      protocol    = "TCP"
      name        = "http"
    }
  }
}

#####
# ConfigMap
#####

resource "kubernetes_config_map" "this" {
  metadata {
    name      = var.config_map_name
    namespace = var.namespace
    annotations = merge(
      var.annotations,
      var.config_map_annotations
    )
    labels = merge(
      {
        "app.kubernetes.io/name"       = "azure-metrics-exporter"
        "app.kubernetes.io/instance"   = var.config_map_name == "" ? var.namespace : var.config_map_name
        "app.kubernetes.io/version"    = "0.6.0"
        "app.kubernetes.io/component"  = "exporter"
        "app.kubernetes.io/part-of"    = "monitoring"
        "app.kubernetes.io/managed-by" = "terraform"
      },
      var.labels,
      var.config_map_labels
    )
  }

  data = {
    "configuration.yaml" = local.configuration
    "azure.toml"         = local.confd_configuration
    "azure.yml.tmpl"     = local.confd_template
  }
}

#####
# Secret
#####

resource "kubernetes_secret" "this" {
  metadata {
    name      = var.secret_name
    namespace = var.namespace
    annotations = merge(
      var.annotations,
      var.secret_annotations
    )
    labels = merge(
      {
        "app.kubernetes.io/name"       = "azure-metrics-exporter"
        "app.kubernetes.io/instance"   = var.secret_name
        "app.kubernetes.io/version"    = "0.6.0"
        "app.kubernetes.io/component"  = "exporter"
        "app.kubernetes.io/part-of"    = "monitoring"
        "app.kubernetes.io/managed-by" = "terraform"
      },
      var.labels,
      var.secret_labels
    )
  }

  data = {
    client_id       = var.client_id
    client_secret   = var.client_secret
    tenant_id       = var.tenant_id
    subscription_id = var.subscription_id
  }

  type = "Opaque"
}
