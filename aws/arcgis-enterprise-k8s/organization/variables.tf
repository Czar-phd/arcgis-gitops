variable "site_id" {
  description = "ArcGIS Enterprise site Id"
  type        = string
  default     = "arcgis-enterprise"

  validation {
    condition     = can(regex("^[a-z0-9-]{3,23}$", var.site_id))
    error_message = "The site_id value must be between 3 and 23 characters long and can consist only of lowercase letters, numbers, and hyphens (-)."
  }
}

variable "deployment_id" {
  description = "ArcGIS Enterprise deployment Id"
  type        = string
  default     = "arcgis-enterprise-k8s"

  validation {
    condition     = can(regex("^[a-z0-9-]{3,23}$", var.deployment_id))
    error_message = "The deployment_id value must be between 3 and 23 characters long and can consist only of lowercase letters, numbers, and hyphens (-)."
  }
}

variable "arcgis_version" {
  description = "ArcGIS Enterprise version"
  type        = string
  default     = "11.2.0"

  validation {
    condition     = contains(["11.1.0", "11.2.0"], var.arcgis_version)
    error_message = "Valid values for arcgis_version variable are 11.1.0 and 11.2.0."
  }
}

variable "helm_charts_version" {
  description = "Helm Charts for ArcGIS Enterprise on Kubernetes version"
  type        = string
  default     = "1.2.0"

  validation {
    condition     = contains(["1.1.0", "1.2.0"], var.helm_charts_version)
    error_message = "Valid values for helm_charts_version variable are 1.1.0 and 1.2.0."
  }
}

variable "upgrade_token" {
  description = "ArcGIS Enterprise organization administrator account token"
  type        = string
  sensitive   = true
  default     = "add_token_here"
}

variable "mandatory_update_target_id" {
  description = "Patch ID of required update"
  type        = string
  default     = ""
}

# variable "registry_host" {
#   description = "The fully qualified domain name (FQDN) of the container registry host (for example, docker.io). ECR registry in the current AWS account and region is used if the value is not specified."
#   type        = string
#   default     = null
# }

variable "registry_repo" {
  description = "Container registry context"
  type        = string
  default     = "esridocker"
}

# variable "container_registry_username" {
#   description = "Container registry username"
#   type        = string
#   default     = null
# }

# variable "container_registry_password" {
#   description = "Container registry password"
#   type        = string
#   sensitive   = true
#   default     = null
# }

variable "arcgis_enterprise_fqdn" {
  description = "The fully qualified domain name (FQDN) to access ArcGIS Enterprise on Kubernetes"
  type        = string

  validation {
    condition     = can(regex("^([a-z0-9]+(-[a-z0-9]+)*\\.)+[a-z]{2,}$", var.arcgis_enterprise_fqdn))
    error_message = "The arcgis_enterprise_fqdn value must be a valid domain name."
  }
}

variable "arcgis_enterprise_context" {
  description = "Context path to be used in the URL for ArcGIS Enterprise on Kubernetes"
  type        = string
  default     = "arcgis"
  
  validation {
    condition     = can(regex("^[a-z0-9]{1,}$", var.arcgis_enterprise_context))
    error_message = "The arcgis_enterprise_context value must be an alphanumeric string."
  }  
}

variable "k8s_cluster_domain" {
  description = "Kubernetes cluster domain"
  type        = string
  default     = "cluster.local"
}

variable "common_verbose" {
  description = "Enable verbose install logging"
  type        = bool
  default     = false
}

# Application configuration variables

variable "configure_enterprise_org" {
  description = "Configure ArcGIS Enterprise on Kubernetes organization"
  type        = bool
  default     = true
}

variable "configure_wait_time_min" {
  description = "Organization admin URL validation timeout in minutes"
  type = number
  default = 15
}

variable "system_arch_profile" {
  description = "ArcGIS Enterprise on Kubernetes architecture profile"
  type        = string
  default     = "standard-availability"

  validation {
    condition     = can(regex("^(development|standard-availability|enhanced-availability)$", var.system_arch_profile))
    error_message = "The system_arch_profile value must be either development, standard-availability, or enhanced-availability."
  }
}

variable "authorization_file_path" {
  description = "ArcGIS Enterprise on Kubernetes authorization file path"
  type        = string
}

variable "license_type_id" {
  description = "User type ID for the primary administrator account"
  type        = string
  default     = "creatorUT"
}

variable "admin_username" {
  description = "ArcGIS Enterprise on Kubernetes organization administrator account username"
  type        = string
  default     = "siteadmin"
}

variable "admin_password" {
  description = "ArcGIS Enterprise on Kubernetes organization administrator account password"
  type        = string
  sensitive   = true
}

variable "admin_email" {
  description = "ArcGIS Enterprise on Kubernetes organization administrator account email"
  type        = string
}

variable "admin_first_name" {
  description = "ArcGIS Enterprise on Kubernetes organization administrator account first name"
  type        = string
}

variable "admin_last_name" {
  description = "ArcGIS Enterprise on Kubernetes organization administrator account last name"
  type        = string
}

variable "security_question_index" {
  description = "ArcGIS Enterprise on Kubernetes organization administrator account security question index"
  type        = number
  default     = 1

  validation {
    condition = var.security_question_index > 0 &&  var.security_question_index < 15
    error_message = "The security_question_index value must be an number between 1 and 14."
  }
}

variable "security_question_answer" {
  description = "ArcGIS Enterprise on Kubernetes organization administrator account security question answer"
  type        = string
  sensitive   = true
}

variable "cloud_config_json_file_path" {
  description = "ArcGIS Enterprise on Kubernetes cloud configuration JSON file path"
  type        = string
  default     = null
}

variable "log_setting" {
  description = "ArcGIS Enterprise on Kubernetes log level"
  type        = string
  default     = "INFO"

  validation {
    condition     = can(regex("^(SEVERE|WARNING|INFO|FINE|VERBOSE|DEBUG)$", var.log_setting))
    error_message = "The log_setting value must be either SEVERE, WARNING, INFO, FINE, VERBOSE, DEBUG."
  }
}

variable "log_retention_max_days" {
  description = "Number of days logs will be retained by the organization"
  type        = number
  default     = 60
  validation {
    condition     = var.log_retention_max_days > 0 && var.log_retention_max_days < 1000
    error_message = "The log_retention_max_days value must be a number between 1 and 999."
  }
}

variable "storage" {
  description = "Storage properties for the data stores"
  type = map(object({
    type   = string
    size   = string
    class  = string
    label1 = string
    label2 = string
  }))
  default = {
    relational = {
      type   = "DYNAMIC"
      size   = "16Gi"
      class  = "gp3"
      label1 = ""
      label2 = ""
    }
    object = {
      type   = "DYNAMIC"
      size   = "32Gi"
      class  = "gp3"
      label1 = ""
      label2 = ""
    }
    memory = {
      type   = "DYNAMIC"
      size   = "16Gi"
      class  = "gp3"
      label1 = ""
      label2 = ""
    }
    queue = {
      type   = "DYNAMIC"
      size   = "16Gi"
      class  = "gp3"
      label1 = ""
      label2 = ""
    }
    indexer = {
      type   = "DYNAMIC"
      size   = "16Gi"
      class  = "gp3"
      label1 = ""
      label2 = ""
    }
    sharing = {
      type   = "DYNAMIC"
      size   = "16Gi"
      class  = "gp3"
      label1 = ""
      label2 = ""
    }
    prometheus = {
      type   = "DYNAMIC"
      size   = "30Gi"
      class  = "gp3"
      label1 = ""
      label2 = ""
    }
    grafana = {
      type   = "DYNAMIC"
      size   = "16Gi"
      class  = "gp3"
      label1 = ""
      label2 = ""
    }
  }
}
