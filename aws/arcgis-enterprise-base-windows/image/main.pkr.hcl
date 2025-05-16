/**
 * # Packer Template for Base ArcGIS Enterprise AMIs
 * 
 * The Packer templates builds EC2 AMI for a specific base ArcGIS Enterprise deployment.
 * 
 * The AMIs are built from a Windows OS base image specified by SSM parameter "/arcgis/${var.site_id}/images/${var.os}".
 * 
 * The template first copies installation media for the ArcGIS Enterprise version 
 * and required third party dependencies from My Esri and public repositories 
 * to the private repository S3 bucket. The files to copy are specified 
 * in ../manifests/arcgis-enterprise-s3files-${var.arcgis_version}.json index file.
 * 
 * Then the template uses python scripts to run SSM commands on the source EC2 instances.
 * 
 * 1. Install AWS CLI
 * 2. Install CloudWatch Agent
 * 3. Install Cinc Client and Chef Cookbooks for ArcGIS
 * 4. Download setups from the private repository S3 bucket.
 * 5. Install base ArcGIS Enterprise applications
 * 6. Install patches for the base ArcGIS Enterprise applications
 * 7. Delete unused files, uninstall Cinc Client, run sysprep
 * 
 * IDs of the AMIs are saved in "/arcgis/${var.site_id}/images/${var.deployment_id}/primary" and 
 * "/arcgis/${var.site_id}/images/${var.deployment_id}/standby" SSM parameters.
 * 
 * ## Requirements
 * 
 * On the machine where Packer is executed:
 * 
 * * Python 3.8 or later with [AWS SDK for Python (Boto3)](https://aws.amazon.com/sdk-for-python/) package must be installed
 * * Path to aws/scripts directory must be added to PYTHONPATH
 * * AWS credentials must be configured.
 * * My Esri user name and password must be specified either using environment variables ARCGIS_ONLINE_USERNAME and ARCGIS_ONLINE_PASSWORD or the input variables.
 * 
 * ## SSM Parameters
 * 
 * The template uses the following SSM parameters:
 * 
 * | SSM parameter name | Description |
 * |--------------------|-------------|
 * | /arcgis/${var.site_id}/chef-client-url/${var.os} | Chef Client URL |
 * | /arcgis/${var.site_id}/cookbooks-url | Chef Cookbooks for ArcGIS archive URL |
 * | /arcgis/${var.site_id}/iam/instance-profile-name | IAM instance profile name|
 * | /arcgis/${var.site_id}/images/${var.os} | Source AMI Id|
 * | /arcgis/${var.site_id}/s3/logs | S3 bucket for SSM commands output |
 * | /arcgis/${var.site_id}/s3/region | S3 buckets region code |
 * | /arcgis/${var.site_id}/s3/repository | Private repository S3 bucket |
 * | /arcgis/${var.site_id}/vpc/subnets | Ids of VPC subnets |
 */

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

packer {
  required_plugins {
    amazon = {
      version = ">= 1.1.1"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

data "amazon-parameterstore" "source_ami" {
  name = "/arcgis/${var.site_id}/images/${var.os}"
  region = var.aws_region  
}

data "amazon-parameterstore" "subnets" {
  name = "/arcgis/${var.site_id}/vpc/subnets"
  region = var.aws_region    
}

data "amazon-parameterstore" "instance_profile_name" {
  name = "/arcgis/${var.site_id}/iam/instance-profile-name"
  region = var.aws_region    
}

data "amazon-parameterstore" "s3_repository" {
  name  = "/arcgis/${var.site_id}/s3/repository"
  region = var.aws_region    
}

data "amazon-parameterstore" "s3_logs" {
  name  = "/arcgis/${var.site_id}/s3/logs"
  region = var.aws_region    
}

data "amazon-parameterstore" "s3_region" {
  name  = "/arcgis/${var.site_id}/s3/region"
  region = var.aws_region    
}

data "amazon-parameterstore" "chef_client_url" {
  name  = "/arcgis/${var.site_id}/chef-client-url/${var.os}"
  region = var.aws_region    
}

data "amazon-parameterstore" "chef_cookbooks_url" {
  name  = "/arcgis/${var.site_id}/cookbooks-url"
  region = var.aws_region    
}

locals {
  manifest_file_path = "${path.root}/../manifests/arcgis-enterprise-s3files-${var.arcgis_version}.json"
  manifest           = jsondecode(file(local.manifest_file_path))
  archives_dir       = local.manifest.arcgis.repository.local_archives
  patches_dir        = local.manifest.arcgis.repository.local_patches
  dotnet_setup       = local.manifest.arcgis.repository.metadata.dotnet_setup
  web_deploy_setup   = local.manifest.arcgis.repository.metadata.web_deploy_setup

  timestamp = formatdate("YYYYMMDDhhmm", timestamp())
  
  main_machine_role = "packer-main"
  main_ami_name  = "arcgis-enterprise-base-${var.arcgis_version}-${var.os}-${local.timestamp}"
  main_ami_description = "Base ArcGIS Enterprise ${var.arcgis_version} AMI for ${var.os}"
  
  software_dir = "C:/Software/*"

  # Platform-specific attributes

  chef_client_url = "{{ssm:/arcgis/${var.site_id}/chef-client-url/${var.os}}}"
}

source "amazon-ebs" "main" {
  region        = var.aws_region
  ami_name      = local.main_ami_name
  ami_description = local.main_ami_description
  instance_type = var.instance_type
  source_ami    = data.amazon-parameterstore.source_ami.value
  subnet_id     = jsondecode(data.amazon-parameterstore.subnets.value).private[0]
  iam_instance_profile = data.amazon-parameterstore.instance_profile_name.value
  communicator = "none"
  
  launch_block_device_mappings {
    device_name = "/dev/sda1"
    volume_type = "gp3"
    volume_size = var.root_volume_size
    // encrypted   = true    
    iops        = 16000
    throughput  = 1000
    delete_on_termination = true
  }

  run_tags = {
    Name               = local.main_ami_name
    ArcGISAutomation   = "arcgis-gitops"
    ArcGISSiteId       = var.site_id    
    ArcGISVersion      = var.arcgis_version
    ArcGISDeploymentId = var.deployment_id    
    ArcGISMachineRole  = local.main_machine_role
  }

  skip_create_ami = var.skip_create_ami
}

build {
  name = var.deployment_id
 
  sources = [
    "source.amazon-ebs.main"
  ]

  # Copy files to private S3 repository
  provisioner "shell-local" {
    env = {
      AWS_DEFAULT_REGION = var.aws_region
    }

    command = "python -m s3_copy_files -f ${local.manifest_file_path} -b ${data.amazon-parameterstore.s3_repository.value}"
  }

  # Install AWS CLI
  provisioner "shell-local" {
    env = {
      AWS_DEFAULT_REGION = var.aws_region
    }

    command = "python -m ssm_install_awscli -s ${var.site_id} -d ${var.deployment_id} -m ${local.main_machine_role} -b ${data.amazon-parameterstore.s3_logs.value}"
  }

  # Install CloudWatch Agent
  provisioner "shell-local" {
    env = {
      AWS_DEFAULT_REGION = var.aws_region
    }

    command = "python -m ssm_package -s ${var.site_id} -d ${var.deployment_id} -m ${local.main_machine_role} -p AmazonCloudWatchAgent -b ${data.amazon-parameterstore.s3_logs.value}"
  }

  # Bootstrap
  provisioner "shell-local" {
    env = {
      AWS_DEFAULT_REGION = var.aws_region
    }

    command = "python -m ssm_bootstrap -s ${var.site_id} -d ${var.deployment_id} -m ${local.main_machine_role} -c ${data.amazon-parameterstore.chef_client_url.value} -k ${data.amazon-parameterstore.chef_cookbooks_url.value} -b ${data.amazon-parameterstore.s3_logs.value}"
  }

  # Download setups
  provisioner "shell-local" {
    env = {
      AWS_DEFAULT_REGION = var.aws_region
      JSON_ATTRIBUTES = base64encode(templatefile(
        local.manifest_file_path, 
        { 
          s3bucket = data.amazon-parameterstore.s3_repository.value, 
          region = data.amazon-parameterstore.s3_region.value
        }))
    }

    command = "python -m ssm_run_chef -s ${var.site_id} -d ${var.deployment_id} -m ${local.main_machine_role} -j /arcgis/${var.site_id}/attributes/arcgis-enterprise-base/image/${var.arcgis_version}/${var.os}/s3files -b ${data.amazon-parameterstore.s3_logs.value} -e 1200"
  }

  # Install
  provisioner "shell-local" {
    env = {
      AWS_DEFAULT_REGION = var.aws_region
      JSON_ATTRIBUTES = base64encode(jsonencode({
        arcgis = {
          version = var.arcgis_version
          run_as_user = var.run_as_user
          run_as_password = var.run_as_password
          configure_windows_firewall = true
          configure_cloud_settings   = false
          repository = {
            archives = local.archives_dir
            setups = "C:\\Software\\Setups"
          }
          server = {
            install_dir = "C:\\Program Files\\ArcGIS\\Server"
            install_system_requirements = true
            wa_name = var.server_web_context
          }
          web_adaptor = {
            install_system_requirements = true
            dotnet_setup_path = "${local.archives_dir}\\${local.dotnet_setup}"
            web_deploy_setup_path = "${local.archives_dir}\\${local.web_deploy_setup}"
            admin_access = true
            reindex_portal_content = false
          }
          data_store = {
            install_dir = "C:\\Program Files\\ArcGIS\\DataStore"
            setup_options = "ADDLOCAL=relational"
            data_dir = "C:\\arcgisdatastore"
            install_system_requirements = true
            preferredidentifier = "hostname"
          }
          portal = {
            install_dir = "C:\\Program Files\\ArcGIS\\Portal"
            install_system_requirements = true
            data_dir = "C:\\arcgisportal"
            preferredidentifier = "hostname"
            wa_name = var.portal_web_context
          }
        }
        run_list = [
          "recipe[arcgis-enterprise::system]",
          "recipe[esri-iis::install]",
          "recipe[arcgis-enterprise::install_portal]",
          "recipe[arcgis-enterprise::webstyles]",
          "recipe[arcgis-enterprise::install_portal_wa]",
          "recipe[arcgis-enterprise::install_server]",
          "recipe[arcgis-enterprise::install_server_wa]",
          "recipe[arcgis-enterprise::install_datastore]"
        ]
      }))
    }

    command = "python -m ssm_run_chef -s ${var.site_id} -d ${var.deployment_id} -m ${local.main_machine_role} -j /arcgis/${var.site_id}/attributes/arcgis-enterprise-base/image/${var.arcgis_version}/${var.os}/install -b ${data.amazon-parameterstore.s3_logs.value} -e 3600"
  }

  # Install patches
  provisioner "shell-local" {
    env = {
      AWS_DEFAULT_REGION = var.aws_region
      JSON_ATTRIBUTES = base64encode(jsonencode({
        arcgis = {
          version = var.arcgis_version
          configure_cloud_settings = false
          repository = {
            patches = local.patches_dir
          }
          portal = {
            patches = var.arcgis_portal_patches
          }
          server = {
            patches = var.arcgis_server_patches
          }
          data_store = {
            patches = var.arcgis_data_store_patches
          }
          web_adaptor = {
            patches = var.arcgis_web_adaptor_patches
          }
        }
        run_list = [
          "recipe[arcgis-enterprise::install_patches]"
        ]
      }))
    }

    command = "python -m ssm_run_chef -s ${var.site_id} -d ${var.deployment_id} -m ${local.main_machine_role} -j /arcgis/${var.site_id}/attributes/arcgis-enterprise-base/image/${var.arcgis_version}/${var.os}/patches -b ${data.amazon-parameterstore.s3_logs.value} -e 3600"
  }

  # Clean up
  provisioner "shell-local" {
    env = {
      AWS_DEFAULT_REGION = var.aws_region
    }

    command = "python -m ssm_clean_up -s ${var.site_id} -d ${var.deployment_id} -m ${local.main_machine_role} -p true -f \"${local.software_dir},C:/Program Files/ArcGIS/Portal/etc/ssl/*\" -b ${data.amazon-parameterstore.s3_logs.value}"
  }

  # Save the build artifacts metadata in packer-manifest.json file.
  # Note: New builds add new artifacts to packer-manifest.json file.
  post-processor "manifest" {
    output = "main-packer-manifest.json"
    strip_path = true
    custom_data = {
      ami_description = local.main_ami_description
    }
  }

  # Retrieve the the AMI Id from main-packer-manifest.json manifest file and save it in SSM parameters.
  post-processor "shell-local" {
    env = {
      AWS_DEFAULT_REGION = var.aws_region
    }

    command = "python -m publish_artifact -p /arcgis/${var.site_id}/images/${var.deployment_id}/primary -f main-packer-manifest.json -r ${build.PackerRunUUID}"
  }

  post-processor "shell-local" {
    env = {
      AWS_DEFAULT_REGION = var.aws_region
    }

    command = "python -m publish_artifact -p /arcgis/${var.site_id}/images/${var.deployment_id}/standby -f main-packer-manifest.json -r ${build.PackerRunUUID}"
  }
}

