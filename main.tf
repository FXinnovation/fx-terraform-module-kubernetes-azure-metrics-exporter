#####
# Locals
#####

locals {
  application_version = "0.9.0"
  labels = {
    "app.kubernetes.io/version"    = local.application_version
    "app.kubernetes.io/component"  = "exporter"
    "app.kubernetes.io/part-of"    = "monitoring"
    "app.kubernetes.io/managed-by" = "terraform"
    "app.kubernetes.io/name"       = "azure-metrics-exporter"
  }
  configuration_key = {
    active_directory_authority_url = var.active_directory_authority_url
    resource_manager_url           = var.resource_manager_url
    targets                        = var.targets
    resource_groups                = var.resource_groups
    resource_tags                  = var.resource_tags
  }
  configuration = {
    configuration = yamlencode(local.configuration_key)
  }
  configuration_yaml  = yamlencode(local.configuration)
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
  count = var.enabled ? 1 : 0

  special = false
  upper   = false
  number  = false
  length  = 8
}

#####
# Deployment
#####

resource "kubernetes_deployment" "this" {
  count = var.enabled ? 1 : 0

  metadata {
    name      = var.deployment_name
    namespace = var.namespace
    annotations = merge(
      var.annotations,
      var.deployment_annotations
    )
    labels = merge(
      {
        "app.kubernetes.io/instance" = var.deployment_name
      },
      local.labels,
      var.labels,
      var.deployment_labels
    )
  }

  spec {
    replicas = var.replicas
    selector {
      match_labels = {
        app = element(concat(random_string.selector.*.result, list("")), 0)
      }
    }
    template {
      metadata {
        annotations = merge(
          {
            "configuration/hash" = sha256(local.configuration_yaml)
            "secret/hash"        = sha256("${var.client_id}${var.client_secret}${var.tenant_id}${var.subscription_id}")
          },
          var.annotations,
          var.deployment_annotations
        )
        labels = merge(
          {
            "app.kubernetes.io/instance" = var.deployment_name
            app                          = element(concat(random_string.selector.*.result, list("")), 0)
          },
          local.labels,
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
            name = element(concat(kubernetes_config_map.this.*.metadata.0.name, list("")), 0)
            items {
              key  = "azure.yml.tmpl"
              path = "azure.yml.tmpl"
            }
          }
        }

        volume {
          name = "confd-config"
          config_map {
            name = element(concat(kubernetes_config_map.this.*.metadata.0.name, list("")), 0)
            items {
              key  = "azure.toml"
              path = "azure.toml"
            }
          }
        }

        volume {
          name = "confd-sources"
          config_map {
            name = element(concat(kubernetes_config_map.this.*.metadata.0.name, list("")), 0)
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
                name = element(concat(kubernetes_secret.this.*.metadata.0.name, list("")), 0)
                key  = "subscription_id"
              }
            }
          }

          env {
            name = "client_id"
            value_from {
              secret_key_ref {
                name = element(concat(kubernetes_secret.this.*.metadata.0.name, list("")), 0)
                key  = "client_id"
              }
            }
          }

          env {
            name = "tenant_id"
            value_from {
              secret_key_ref {
                name = element(concat(kubernetes_secret.this.*.metadata.0.name, list("")), 0)
                key  = "tenant_id"
              }
            }
          }

          env {
            name = "client_secret"
            value_from {
              secret_key_ref {
                name = element(concat(kubernetes_secret.this.*.metadata.0.name, list("")), 0)
                key  = "client_secret"
              }
            }
          }
        }

        container {
          name              = "azure-metrics-exporter"
          image             = "fxinnovation/azure_metrics_exporter:${local.application_version}"
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
  count = var.enabled ? 1 : 0

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
        "app.kubernetes.io/instance" = var.service_name
      },
      local.labels,
      var.labels,
      var.service_labels
    )
  }

  spec {
    selector = {
      app = element(concat(random_string.selector.*.result, list("")), 0)
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
  count = var.enabled ? 1 : 0

  metadata {
    name      = var.config_map_name
    namespace = var.namespace
    annotations = merge(
      var.annotations,
      var.config_map_annotations
    )
    labels = merge(
      {
        "app.kubernetes.io/instance" = var.config_map_name
      },
      local.labels,
      var.labels,
      var.config_map_labels
    )
  }

  data = {
    "configuration.yaml" = local.configuration_yaml
    "azure.toml"         = local.confd_configuration
    "azure.yml.tmpl"     = local.confd_template
  }
}

#####
# Secret
#####

resource "kubernetes_secret" "this" {
  count = var.enabled ? 1 : 0

  metadata {
    name      = var.secret_name
    namespace = var.namespace
    annotations = merge(
      var.annotations,
      var.secret_annotations
    )
    labels = merge(
      {
        "app.kubernetes.io/instance" = var.secret_name
      },
      local.labels,
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
