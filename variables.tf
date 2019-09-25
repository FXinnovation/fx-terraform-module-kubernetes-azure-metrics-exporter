variable "enabled" {
  default     = true
  description = "Whether to enable the azure-metrics-exporter module."
}

variable "targets" {
  default     = []
  description = "List of maps of the target part of azure-metrics-exporter's configuration."
}

variable "resource_groups" {
  default     = []
  description = "List of maps of the resource_group part of azure-metrics-exporter's configuration."
}

variable "resource_tags" {
  default     = []
  description = "List of maps of the resource_tags part of azure-metrics-exporter's configuration."
}

variable "active_directory_authority_url" {
  default     = "https://login.microsoftonline.com/"
  description = "Active Directory authority URL used by azure-metrcis-exporter."
}

variable "resource_manager_url" {
  description = "Resource manager URL used by azure-metrcis-exporter."
  default     = "https://management.azure.com/"
}

variable "deployment_name" {
  description = "Name of the deployment that will be create, if left empty, will default to 'azure-metrics-exporter'"
  default     = "azure-metrics-exporter"
}

variable "namespace" {
  description = "Namespace in which the module will be deployed."
  default     = "default"
}

variable "annotations" {
  description = "Additionnal annotations that will be merged on all resources."
  default     = {}
}

variable "deployment_annotations" {
  description = "Additionnal annotations that will be merged on the deployment."
  default     = {}
}

variable "labels" {
  description = "Additionnal labels that will be merged on all resources."
  default     = {}
}

variable "deployment_labels" {
  description = "Additionnal labels that will be merged on the deployment."
  default     = {}
}

variable "replicas" {
  description = "Number of replicas to deploy."
  default     = 1
}

variable "image_pull_policy" {
  description = "Image pull policy on the main container."
  default     = "IfNotPresent"
}

variable "service_name" {
  description = "Name of the service that will be create"
  default     = "azure-metrics-exporter"
}

variable "service_annotations" {
  description = "Additionnal annotations that will be merged for the service."
  default     = {}
}

variable "service_labels" {
  description = "Additionnal labels that will be merged for the service."
  default     = {}
}

variable "port" {
  description = "Port to be used for the service."
  default     = 80
}

variable "config_map_name" {
  description = "Name of the config map that will be created."
  default     = "azure-metrics-exporter"
}

variable "config_map_annotations" {
  description = "Additionnal annotations that will be merged for the config map."
  default     = {}
}

variable "config_map_labels" {
  description = "Additionnal labels that will be merged for the config map."
  default     = {}
}

variable "secret_name" {
  description = "Name of the secret that will be created."
  default     = "azure-metrics-exporter"
}

variable "secret_annotations" {
  description = "Additionnal annotations that will be merged for the secret."
  default     = {}
}

variable "secret_labels" {
  description = "Additionnal labels that will be merged for the secret."
  default     = {}
}

variable "client_id" {
  description = "Client ID that will be used by the azure-metrics-exporter."
  type        = string
}

variable "client_secret" {
  description = "Client secret that will be used by the azure-metrics-exporter."
  type        = string
}

variable "tenant_id" {
  description = "Tenant ID that will be used by the azure-metrics-exporter."
  type        = string
}

variable "subscription_id" {
  description = "Subscription ID that will be used by the azure-metrics-exporter."
  type        = string
}
