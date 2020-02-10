# terraform-module-kubernetes-azure-metrics-exporter

Terraform module to deploy azure-metrics-exporter on kubernetes.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Providers

| Name | Version |
|------|---------|
| kubernetes | n/a |
| random | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:-----:|
| active\_directory\_authority\_url | Active Directory authority URL used by azure-metrcis-exporter. | `string` | `"https://login.microsoftonline.com/"` | no |
| annotations | Additionnal annotations that will be merged on all resources. | `map` | `{}` | no |
| client\_id | Client ID that will be used by the azure-metrics-exporter. | `string` | n/a | yes |
| client\_secret | Client secret that will be used by the azure-metrics-exporter. | `string` | n/a | yes |
| config\_map\_annotations | Additionnal annotations that will be merged for the config map. | `map` | `{}` | no |
| config\_map\_labels | Additionnal labels that will be merged for the config map. | `map` | `{}` | no |
| config\_map\_name | Name of the config map that will be created. | `string` | `"azure-metrics-exporter"` | no |
| deployment\_annotations | Additionnal annotations that will be merged on the deployment. | `map` | `{}` | no |
| deployment\_labels | Additionnal labels that will be merged on the deployment. | `map` | `{}` | no |
| deployment\_name | Name of the deployment that will be create, if left empty, will default to 'azure-metrics-exporter' | `string` | `"azure-metrics-exporter"` | no |
| enabled | Whether or not to enable this module. | `bool` | `true` | no |
| image\_pull\_policy | Image pull policy on the main container. | `string` | `"IfNotPresent"` | no |
| labels | Additionnal labels that will be merged on all resources. | `map` | `{}` | no |
| namespace | Namespace in which the module will be deployed. | `string` | `"default"` | no |
| port | Port to be used for the service. | `number` | `80` | no |
| replicas | Number of replicas to deploy. | `number` | `1` | no |
| resource\_groups | List of maps of the resource\_group part of azure-metrics-exporter's configuration. | `list` | `[]` | no |
| resource\_manager\_url | Resource manager URL used by azure-metrcis-exporter. | `string` | `"https://management.azure.com/"` | no |
| resource\_tags | List of maps of the resource\_tags part of azure-metrics-exporter's configuration. | `list` | `[]` | no |
| secret\_annotations | Additionnal annotations that will be merged for the secret. | `map` | `{}` | no |
| secret\_labels | Additionnal labels that will be merged for the secret. | `map` | `{}` | no |
| secret\_name | Name of the secret that will be created. | `string` | `"azure-metrics-exporter"` | no |
| service\_annotations | Additionnal annotations that will be merged for the service. | `map` | `{}` | no |
| service\_labels | Additionnal labels that will be merged for the service. | `map` | `{}` | no |
| service\_name | Name of the service that will be create | `string` | `"azure-metrics-exporter"` | no |
| subscription\_id | Subscription ID that will be used by the azure-metrics-exporter. | `string` | n/a | yes |
| targets | List of maps of the target part of azure-metrics-exporter's configuration. | `list` | `[]` | no |
| tenant\_id | Tenant ID that will be used by the azure-metrics-exporter. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| config\_map\_name | Name of the config\_map created by this module. |
| deployment\_name | Name of the deployment created by this module. |
| namespace | Namespace in which the module is deployed. |
| port | Port on which the service listens. |
| secret\_name | Name of the secret created by this module. |
| service\_name | Name of the service created by this module. |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
