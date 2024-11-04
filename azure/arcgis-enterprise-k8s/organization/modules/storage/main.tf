/**
 * # Terraform module storage
 * 
 * The module:
 * 
 * * Creates an Azure resource group for the organization's stores,
 * * Creates an Azure storage account and a blob container for the organization's object store, 
 * * Grants the specified principal Storage Blob Data Contributor role in the storage accounts, and
 * * Creates cloud config JSON file for the object store.
 */

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

resource "random_id" "storage_account_suffix" {
  keepers = {
    # Generate a new id each time we switch to a new site id or deployment id
    site_id       = var.site_id
    deployment_id = var.deployment_id
  }

  byte_length = 8
}

resource "azurerm_resource_group" "storage" {
  name     = "${var.deployment_id}-storage"
  location = var.azure_region
}

resource "azurerm_storage_account" "deployment_storage" {
  name                     = "arcgis${random_id.storage_account_suffix.hex}"
  resource_group_name      = azurerm_resource_group.storage.name
  location                 = var.azure_region
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    ArcGISSiteId       = var.site_id
    ArcGISDeploymentId = var.deployment_id
  }
}

# Create blob container for the organization object store if cloud_config_json_file_path is not specified.
resource "azurerm_storage_container" "object_store" {
  name                  = "object-store"
  storage_account_name  = azurerm_storage_account.deployment_storage.name
  container_access_type = "private"
}

# Assign Storage Blob Data Contributor role to the AKS cluster identity
resource "azurerm_role_assignment" "storage_blob_data_contributor" {
  principal_id                     = var.principal_id
  role_definition_name             = "Storage Blob Data Contributor"
  scope                            = azurerm_storage_account.deployment_storage.id
  skip_service_principal_aad_check = true
}

# Create cloud-config.json file for cloud stores in the Helm chart's user-input diectory
# if the file path is specified either by cloud_config_json_file_path input variable
# or configured with the default setings.

resource "local_sensitive_file" "cloud_config_json_file" {
  content = jsonencode([{
      name = "AZURE"
      credential = {
        type = "USER-ASSIGNED-IDENTITY"
        # type = "STORAGE-ACCOUNT-KEY"
        managedIdentityClientId = var.client_id
        secret = {
          storageAccountName = azurerm_storage_account.deployment_storage.name
          # storageAccountKey  = azurerm_storage_account.deployment_storage[0].primary_access_key
        }
      }
      cloudServices = [{
        name  = "Azure Blob Store"
        type  = "objectStore"
        usage = "DEFAULT"
        connection = {
          containerName = azurerm_storage_container.object_store.name
          # regionEndpointUrl = "https://${module.site_core_info.storage_account_name}.blob.core.windows.net"
          accountEndpointUrl = trimsuffix(azurerm_storage_account.deployment_storage.primary_blob_endpoint, "/")
          # rootDir = var.deployment_id
        }
        category = "storage"
      }]
  }])
  filename = var.cloud_config_json_file_path
}
