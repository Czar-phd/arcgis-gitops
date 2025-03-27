# Copyright 2024-2025 Esri
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

variable "aws_region" {
  description = "AWS region Id"
  type        = string
}

variable "site_id" {
  description = "ArcGIS Enterprise site Id"
  type        = string
  default     = "arcgis"

  validation {
    condition     = can(regex("^[a-z0-9-]{3,6}$", var.site_id))
    error_message = "The site_id value must be between 3 and 6 characters long and can consist only of lowercase letters, numbers, and hyphens (-)."
  }
}

variable "eks_version" {
  description = "The desired Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.28"
  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+$", var.eks_version))
    error_message = "The eks_version value must be in the format of major.minor, for example, 1.29"
  }
}

variable "subnet_ids" {
  description = "EKS cluster subnet IDs (by default, the first two public, two private, and two internal VPC subnets are used)"
  type        = list(string)
  default     = []
}

variable "node_groups" {
  # description = "EKS Node Groups configuration"
  description = <<EOT
  <p>EKS node groups configuration properties:</p>
  <ul>
  <li>name - Name of the node group</li>
  <li>instance_type -Type of EC2 instance to use for the node group</li>
  <li>root_volume_size - Size of the root volume in GB</li>
  <li>desired_size - Number of nodes to start with</li>
  <li>max_size - Maximum number of nodes in the node group</li>
  <li>min_size - Minimum number of nodes in the node group</li>
  <li>subnet_ids - List of subnet IDs to use for the node group (the first two private subnets are used by default)</li>
  </ul>
  EOT  
  type = list(object({
    name             = string
    instance_type    = string
    root_volume_size = number
    desired_size     = number
    max_size         = number
    min_size         = number
    subnet_ids       = list(string)
  }))
  default = [
    {
      name             = "default"
      instance_type    = "m6i.2xlarge"
      root_volume_size = 1024
      desired_size     = 4
      max_size         = 8
      min_size         = 4
      subnet_ids       = []
    }
  ]
}

variable "key_name" {
  description = "EC2 key pair name"
  type        = string
  default     = null
}

variable "pull_through_cache" {
  description = "Configure ECR pull through cache rules"
  type        = bool
  default     = true
}

variable "container_registry_url" {
  description = "Source container registry URL"
  type        = string
  default     = "registry-1.docker.io"
}

variable "ecr_repository_prefix" {
  description = "The repository name prefix to use when caching images from the source registry"
  type        = string
  default     = "docker-hub"
}

variable "container_registry_user" {
  description = "Source container registry user name"
  type        = string
  default     = null
}

variable "container_registry_password" {
  description = "Source container registry user password"
  type        = string
  sensitive   = true
  default     = null
}

variable "enable_waf" {
  description = "Enable WAF and Shield addons for ALB"
  type        = bool
  default     = true
}

variable "containerinsights_log_retention" {
  description = "The number of days to retain CloudWatch Container Insights log events"
  type        = number
  default     = 90
}
