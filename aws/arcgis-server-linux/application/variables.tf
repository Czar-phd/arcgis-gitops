variable "admin_email" {
  description = "ArcGIS Server administrator e-mail address"
  type        = string
}

variable "admin_password" {
  description = "Primary ArcGIS Server administrator user password"
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^[a-zA-Z0-9.]{8,128}$", var.admin_password))
    error_message = "The admin_password value must be between 8 and 128 characters long and can consist only of uppercase and lowercase ASCII letters, numbers, and dots (.)."
  }
}

variable "admin_username" {
  description = "Primary ArcGIS Server administrator user name"
  type        = string
  default     = "siteadmin"

  validation {
    condition     = can(regex("^[a-zA-Z0-9.]{6,128}$", var.admin_username))
    error_message = "The admin_username value must be between 6 and 128 characters long and can consist only of uppercase and lowercase ASCII letters, numbers, and dots (.)."
  }
}

variable "arcgis_online_password" {
  description = "ArcGIS Online user password"
  type        = string
  sensitive   = true
  default     = null
}

variable "arcgis_online_username" {
  description = "ArcGIS Online user name"
  type        = string
  default     = null
}

variable "arcgis_server_patches" {
  description = "File names of ArcGIS Server patches to install."
  type        = list(string)
  default     = []
}

variable "arcgis_version" {
  description = "ArcGIS Server version"
  type        = string
  default     = "11.3"

  validation {
    condition     = contains(["11.2", "11.3"], var.arcgis_version)
    error_message = "Valid values for arcgis_version variable are 11.2 and 11.3."
  }
}

variable "config_store_type" {
  description = "ArcGIS Server configuration store type"
  type        = string
  default     = "FILESYSTEM"

  validation {
    condition     = contains(["FILESYSTEM", "AMAZON"], var.config_store_type)
    error_message = "Valid values for the config_store_type variable are FILESYSTEM and AMAZON"
  }
}

variable "deployment_fqdn" {
  description = "Fully qualified domain name of the ArcGIS Server deployment"
  type        = string

  validation {
    condition     = can(regex("^([a-z0-9]+(-[a-z0-9]+)*\\.)+[a-z]{2,}$", var.deployment_fqdn))
    error_message = "The deployment_fqdn value must be a valid domain name."
  }
}

variable "deployment_id" {
  description = "Deployment Id"
  type        = string
  default     = "arcgis-server"

  validation {
    condition     = can(regex("^[a-z0-9-]{3,23}$", var.deployment_id))
    error_message = "The deployment_id value must be between 3 and 23 characters long and can consist only of lowercase letters, numbers, and hyphens (-)."
  }
}

variable "is_upgrade" {
  description = "Flag to indicate if this is an upgrade deployment"
  type        = bool
  default     = false
}

variable "log_level" {
  description = "ArcGIS Enterprise applications log level"
  type        = string
  default     = "WARNING"
  validation {
    # Log levels supported by both ArcGIS Server and Portal for ArcGIS
    condition     = contains(["SEVERE", "WARNING", "INFO", "FINE", "VERBOSE", "DEBUG"], var.log_level)
    error_message = "Valid values for the log_level variable are SEVERE, WARNING, INFO, FINE, VERBOSE, and DEBUG"
  }
}

variable "os" {
  description = "Operating system id (rhel8|rhel9)"
  type        = string
  default     = "rhel8"

  validation {
    condition     = contains(["rhel8", "rhel9"], var.os)
    error_message = "Valid values for os variable are rhel8, rhel9."
  }
}

variable "portal_org_id" {
  description = "ArcGIS Enterprise organization Id"
  type        = string
  default     = null
}

variable "portal_password" {
  description = "Portal for ArcGIS user password"
  type        = string
  sensitive   = true
  default     = null
}

variable "portal_url" {
  description = "Portal for ArcGIS URL"
  type        = string
  default     = null
}

variable "portal_username" {
  description = "Portal for ArcGIS user name"
  type        = string
  default     = null
} 

variable "run_as_user" {
  description = "User name for the account used to run ArcGIS Server."
  type        = string
  default     = "arcgis"
}

variable "server_authorization_file_path" {
  description = "Local path of ArcGIS Server authorization file"
  type        = string
}

variable "server_functions" {
  description = "Functions of the federated server"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for f in var.server_functions : contains(["GeoAnalytics", "RasterAnalytics", "ImageHosting", "KnowledgeServer"], f)
    ])
    error_message = "Valid values for server_functions list elements are GeoAnalytics, RasterAnalytics, ImageHosting, and KnowledgeServer"
  }
}

variable "server_role" {
  description = "ArcGIS Server role"
  type        = string
  default     = ""

  validation {
    condition     = contains(["", "FEDERATED_SERVER", "FEDERATED_SERVER_WITH_RESTRICTED_PUBLISHING", "HOSTING_SERVER"], var.server_role)
    error_message = "Valid values for the server_role variable are FEDERATED_SERVER, FEDERATED_SERVER_WITH_RESTRICTED_PUBLISHING, and HOSTING_SERVER"
  }
}

variable "services_dir_enabled" {
  description = "Enable REST handler services directory"
  type        = bool
  default     = true
}

variable "site_id" {
  description = "ArcGIS Enterprise site Id"
  type        = string
  default     = "arcgis-enterprise"

  validation {
    condition     = can(regex("^[a-z0-9-]{3,23}$", var.site_id))
    error_message = "The site_id value must be between 3 and 23 characters long and can consist only of lowercase letters, numbers, and hyphens (-)."
  }
}

variable "system_properties" {
  description = "ArcGIS Server system properties"
  type        = map(any)
  default     = {}
}
