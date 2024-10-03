<!-- BEGIN_TF_DOCS -->
# Terraform Module K8s-cluster

The Terraform module provisions Azure Kubernetes Service (AKS) cluster
that meets [ArcGIS Enterprise on Kubernetes system requirements](https://enterprise-k8s.arcgis.com/en/latest/deploy/deploy-a-cluster-in-azure-kubernetes-service.htm).

![Azure Kubernetes Service (AKS) cluster](k8s-cluster.png "Azure Kubernetes Service (AKS) cluster")

The module creates a resource group with the following Azure resouces:

* AKS cluster with default node pool in the private subnet 1 and ingress controller in App Gateway subnet 1.
* Container registry with private endpoint in isolated subnet 1, private DNS zone, and cache rules to pull images from Docker Hub container registry.
* Monitoring subsyatem that include Azure Monitor workspace and Azure Managed Grafana instances.

Once the AKS cluster is available, the module creates storage classes for Azure Disk CSI driver.

## Requirements

The subnets and virtual network Ids are retrieved from Azure Key Vault secrets. The key vault, subnets, and other
network infrastructure resources must be created by the [infrastructure-core](../infrastructure-core) module.

On the machine where Terraform is executed:

* Azure subscription Id must be specified by ARM_SUBSCRIPTION_ID environment variable.
* Azure service principal credentials must be configured by ARM_CLIENT_ID, ARM_TENANT_ID, and ARM_CLIENT_SECRET environment variables.
* Azure CLI and kubectl must be installed.

## Providers

| Name | Version |
|------|---------|
| azurerm | ~> 4.1 |
| null | n/a |
| random | n/a |

## Resources

| Name | Type |
|------|------|
| [azurerm_container_registry.cluster_acr](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_registry) | resource |
| [azurerm_container_registry_cache_rule.pull_through_cache](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_registry_cache_rule) | resource |
| [azurerm_dashboard_grafana.grafana](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/dashboard_grafana) | resource |
| [azurerm_key_vault_secret.cr_password](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) | resource |
| [azurerm_key_vault_secret.cr_user](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) | resource |
| [azurerm_kubernetes_cluster.site_cluster](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster) | resource |
| [azurerm_monitor_alert_prometheus_rule_group.kubernetes_recording_rules_rule_group](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_alert_prometheus_rule_group) | resource |
| [azurerm_monitor_alert_prometheus_rule_group.node_recording_rules_rule_group](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_alert_prometheus_rule_group) | resource |
| [azurerm_monitor_alert_prometheus_rule_group.ux_recording_rules_rule_group](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_alert_prometheus_rule_group) | resource |
| [azurerm_monitor_data_collection_rule_association.dcra](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_data_collection_rule_association) | resource |
| [azurerm_monitor_workspace.prometheus](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_workspace) | resource |
| [azurerm_private_dns_zone.acr_private_dns_zone](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone) | resource |
| [azurerm_private_dns_zone_virtual_network_link.acr_private_dns_zone_virtual_network_link](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone_virtual_network_link) | resource |
| [azurerm_private_endpoint.acr_private_endpoint](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) | resource |
| [azurerm_resource_group.cluster_rg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [azurerm_resource_provider_registration.microsoft_dashboard](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_provider_registration) | resource |
| [azurerm_resource_provider_registration.microsoft_monitor](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_provider_registration) | resource |
| [azurerm_role_assignment.acr](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.data_reader_role](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [null_resource.credential_set](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.storage_class](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.update_kubeconfig](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [random_id.container_registry_suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |
| [azurerm_key_vault.site_vault](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/key_vault) | data source |
| [azurerm_key_vault_secret.app_gateway_subnet_1](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/key_vault_secret) | data source |
| [azurerm_key_vault_secret.internal_subnet_1](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/key_vault_secret) | data source |
| [azurerm_key_vault_secret.private_subnet_1](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/key_vault_secret) | data source |
| [azurerm_key_vault_secret.vnet_id](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/key_vault_secret) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| azure_region | Azure region | `string` | `"East US"` | no |
| container_registry_password | Source container registry user password | `string` | `null` | no |
| container_registry_url | Source container registry URL | `string` | `"docker.io"` | no |
| container_registry_user | Source container registry user name | `string` | `null` | no |
| default_node_pool | <p>Default AKS node pool configuration properties:</p>   <ul>   <li>name - The name which should be used for the default Kubernetes Node Pool</li>   <li>vm_size - The size of the Virtual Machine</li>   <li>os_disk_size_gb - The size of the OS Disk which should be used for each agent in the Node Pool</li>   <li>node_count - The initial number of nodes which should exist in this Node Pool</li>   <li>max_count - The maximum number of nodes which should exist in this Node Pool</li>   <li>min_count - The minimum number of nodes which should exist in this Node Pool</li>   </ul> | ```object({ name = string vm_size = string os_disk_size_gb = number node_count = number max_count = number min_count = number })``` | ```{ "max_count": 8, "min_count": 4, "name": "default", "node_count": 4, "os_disk_size_gb": 1024, "vm_size": "Standard_D4s_v5" }``` | no |
| site_id | ArcGIS Enterprise site Id | `string` | `"arcgis-enterprise"` | no |

## Outputs

| Name | Description |
|------|-------------|
| cluster_name | AKS cluster name |
| cluster_resource_group | AKS cluster resource group |
| container_registry_login_server | Container registry login server |
| grafana_endpoint | Grafana endpoint |
| prometheus_query_endpoint | Prometheus query endpoint |
| subscription_id | Azure subscription Id |
<!-- END_TF_DOCS -->