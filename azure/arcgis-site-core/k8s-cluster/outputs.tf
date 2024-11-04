# Copyright 2024 Esri
#
# Licensed under the Apache License Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

output "cluster_name" {
  value       = azurerm_kubernetes_cluster.site_cluster.name
  description = "AKS cluster name"
}

output "subscription_id" {
  value       = data.azurerm_client_config.current.subscription_id
  description = "Azure subscription Id"
}

output "cluster_resource_group" {
  value       = azurerm_resource_group.cluster_rg.name
  description = "AKS cluster resource group"
}

output "acr_login_server" {
  value       = module.container_registry.acr_login_server
  description = "Private container registry login server"
}

output "alb_id" {
  description = "The ID of the Azure Application Load Balancer"
  value       = module.alb_controller.alb_id
}

output "prometheus_query_endpoint" {
  value       = module.monitoring.prometheus_query_endpoint
  description = "Prometheus query endpoint"
}

output "grafana_endpoint" {
  value       = module.monitoring.grafana_endpoint
  description = "Grafana endpoint"
}
