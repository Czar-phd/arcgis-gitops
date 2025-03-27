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
  description = "ArcGIS site Id"
  type        = string
  default     = "arcgis"

  validation {
    condition     = can(regex("^[a-z0-9-]{3,6}$", var.site_id))
    error_message = "The site_id value must be between 3 and 6 characters long and can consist only of lowercase letters, numbers, and hyphens (-)."
  }
}

variable "deployment_id" {
  description = "ArcGIS Enterprise deployment Id"
  type        = string
  default     = "enterprise-base-windows"

  validation {
    condition     = can(regex("^[a-z0-9-]{3,25}$", var.deployment_id))
    error_message = "The deployment_id value must be between 3 and 25 characters long and can consist only of lowercase letters, numbers, and hyphens (-)."
  }  
}

variable "client_cidr_blocks" {
  description = "Client CIDR blocks"
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition = alltrue([
      for b in var.client_cidr_blocks : can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}\\/[0-9]{1,2}$", b))
    ])
    error_message = "All elements in vpc_cidr_block list must be in IPv4 CIDR block format."
  }
}

variable "subnet_ids" {
  description = "EC2 instances subnet IDs (by default, the first two private VPC subnets are used)"
  type        = list(string)
  default     = []
}

variable "internal_load_balancer" {
  description = "If true, the load balancer scheme is set to 'internal'"
  type        = bool
  default     = false
}

variable "ssl_certificate_arn" {
  description = "SSL certificate ARN for HTTPS listener of the load balancer"
  type        = string

  validation {
    condition     = can(regex("^arn:.+:acm:.+:\\d+:certificate\\/.+$", var.ssl_certificate_arn))
    error_message = "The ssl_certificate_arn value must be an ACM certificate ARN."
  }
}

variable "ssl_policy" {
  description = "Security Policy that should be assigned to the ALB to control the SSL protocol and ciphers"
  type        = string
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

variable "deployment_fqdn" {
  description = "Fully qualified domain name of the base ArcGIS Enterprise deployment"
  type        = string

  validation {
    condition     = can(regex("^([a-z0-9]+(-[a-z0-9]+)*\\.)+[a-z]{2,}$", var.deployment_fqdn))
    error_message = "The deployment_fqdn value must be a valid domain name."
  }
}

variable "portal_web_context" {
  description = "Portal for ArcGIS web context"
  type        = string
  default     = "portal"  
}

variable "server_web_context" {
  description = "ArcGIS Server web context"
  type        = string
  default     = "server"  
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "m6i.2xlarge"
}

variable "root_volume_size" {
  description = "Root EBS volume size in GB of primary and standby EC2 instances"
  type        = number
  default     = 1024
  
  validation {
    condition     = var.root_volume_size >= 100   && var.root_volume_size <= 16384
    error_message = "The root_volume_size value must be between 100 and 16384."
  }    
}

variable "root_volume_iops" {
  description = "Root EBS volume IOPS of primary and standby EC2 instances"
  type        = number
  default     = 3000

  validation {
    condition     = var.root_volume_iops >= 3000   && var.root_volume_iops <= 16000
    error_message = "The root_volume_iops value must be between 3000 and 16000."
  }    
}

variable "root_volume_throughput" {
  description = "Root EBS volume throughput in MB/s of primary and standby EC2 instances"
  type        = number
  default     = 125

  validation {
    condition     = var.root_volume_throughput >= 125 && var.root_volume_throughput <= 1000
    error_message = "The root_volume_throughput value must be between 125 and 1000."
  }
}

variable "fileserver_instance_type" {
  description = "EC2 instance type of fileserver"
  type        = string
  default     = "m6i.xlarge"
}

variable "fileserver_volume_size" {
  description = "Root EBS volume size in GB of fileserver EC2 instance"
  type        = number
  default     = 1024

  validation {
    condition     = var.fileserver_volume_size >= 100   && var.fileserver_volume_size <= 16384
    error_message = "The fileserver_volume_size value must be between 100 and 16384."
  }    
}

variable "fileserver_volume_iops" {
  description = "Root EBS volume IOPS of fileserver EC2 instance"
  type        = number
  default     = 3000

  validation {
    condition     = var.fileserver_volume_iops >= 3000 && var.fileserver_volume_iops <= 16000
    error_message = "The fileserver_volume_iops value must be between 3000 and 16000."
  }    
}

variable "fileserver_volume_throughput" {
  description = "Root EBS volume throughput in MB/s of fileserver EC2 instance"
  type        = number
  default     = 125

  validation {
    condition     = var.fileserver_volume_throughput >= 125   && var.fileserver_volume_throughput <= 1000
    error_message = "The fileserver_volume_throughput value must be between 125 and 1000."
  }
}

variable "key_name" {
  description = "EC2 key pair name"
  type        = string
}
