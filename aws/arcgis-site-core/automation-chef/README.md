<!-- BEGIN_TF_DOCS -->
# Terraform module automation-chef

The module provisions AWS resources required for ArcGIS Enterprise site configuration management
using IT automation tool Chef/Cinc:

* Looks up the latest AMIs for the supported operating systems
* Copies Chef/Cinc client setups and Chef cookbooks for ArcGIS distribution archive from the URLs specified
in [automation-chef-files.json](manifests/automation-chef-files.json) file to the private repository S3 bucket
* Creates SSM documents for the ArcGIS Enterprise site

The AMI IDs for each operating system as well as S3 URLs are stored in SSM parameters:

| SSM parameter name | Description |
| --- | --- |
| /arcgis/${var.site_id}/images/${os} | Ids of the latest AMI for the operating systems |
| /arcgis/${var.site_id}/chef-client-url/${os} | S3 URLs of Cinc Client setup for the operating systems |
| /arcgis/${var.site_id}/cookbooks-url | S3 URL of Chef cookbooks for ArcGIS distribution archive |

SSM documents created by the module:

| SSM document name | Description |
| --- | --- |
| ${var.site_id}-bootstrap | Installs Chef/Cinc Client and Chef Cookbooks for ArcGIS on EC2 instances |
| ${var.site_id}-clean-up | Deletes temporary files created by Chef runs |
| ${var.site_id}-install-awscli | Installs AWS CLI on EC2 instances |
| ${var.site_id}-nfs-mount | Mounts NFS target on EC2 instances |
| ${var.site_id}-run-chef | Runs Chef in solo ode with specified JSON attributes |

## Requirements

On the machine where Terraform is executed:

* Python 3.8 or later with [AWS SDK for Python (Boto3)](https://aws.amazon.com/sdk-for-python/) package must be installed
* Path to aws/scripts directory must be added to PYTHONPATH
* The working directory must be set to the automation-chef module path (because [automation-chef-files.json](manifests/automation-chef-files.json) uses relative path to the Chef cookbooks archive)
* AWS credentials must be configured.
* AWS region must be specified by AWS_DEFAULT_REGION environment variable.

Before using the module, the repository S3 bucket must be created by infrastructure-core terraform module.

## Providers

| Name | Version |
|------|---------|
| aws | ~> 5.22 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| s3_copy_files | ../../modules/s3_copy_files | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_ssm_document.bootstrap_command](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_document) | resource |
| [aws_ssm_document.clean_up_command](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_document) | resource |
| [aws_ssm_document.install_awscli_command](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_document) | resource |
| [aws_ssm_document.nfs_mount_command](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_document) | resource |
| [aws_ssm_document.run_chef_command](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_document) | resource |
| [aws_ssm_parameter.arcgis_cookbooks_url](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.chef_client_log_level](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.chef_client_urls](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.images_parameters](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ami.os_image](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_ssm_parameter.s3_repository](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| arcgis_cookbooks_path | S3 repository key of Chef cookbooks for ArcGIS distribution archive in the repository bucket | `string` | `"cookbooks/arcgis-5.0.0-cookbooks.tar.gz"` | no |
| chef_client_paths | Chef/CINC Client setup S3 keys by operating system | `map(any)` | ```{ "rhel8": { "description": "Chef Client setup S3 key for Red Hat Enterprise Linux version 8", "path": "cinc/cinc-18.4.2-1.el8.x86_64.rpm" }, "rhel9": { "description": "Chef Client setup S3 key for Red Hat Enterprise Linux version 9", "path": "cinc/cinc-18.4.2-1.el9.x86_64.rpm" }, "sles15": { "description": "Chef Client setup S3 key for SUSE Linux Enterprise Server 15", "path": "cinc/cinc-18.4.2-1.sles15.x86_64.rpm" }, "ubuntu20": { "description": "Chef Client setup S3 key for Ubuntu 20.04 LTS", "path": "cinc/cinc_18.4.2-1_amd64.deb" }, "ubuntu22": { "description": "Chef Client setup S3 key for Ubuntu 22.04 LTS", "path": "cinc/cinc_18.4.2-1_amd64.deb" }, "windows2022": { "description": "Chef Client setup S3 key for Microsoft Windows Server 2022", "path": "cinc/cinc-18.4.2-1-x64.msi" } }``` | no |
| images | AMI search filters by opeating system | `map(any)` | ```{ "rhel8": { "ami_name_filter": "RHEL-8.6.0_HVM-*-x86_64-2-Hourly2-GP2", "description": "Red Hat Enterprise Linux version 8 (HVM), EBS General Purpose (SSD) Volume Type", "owner": "309956199498" }, "rhel9": { "ami_name_filter": "RHEL-9.3.0_HVM-*-x86_64-5-Hourly2-GP2", "description": "Red Hat Enterprise Linux version 9 (HVM), EBS General Purpose (SSD) Volume Type", "owner": "309956199498" }, "sles15": { "ami_name_filter": "suse-sles-15-*-v*-hvm-ssd-x86_64", "description": "SUSE Linux Enterprise Server 15 (HVM, 64-bit, SSD-Backed)", "owner": "013907871322" }, "ubuntu20": { "ami_name_filter": "ubuntu/images/hvm-ssd/ubuntu-*20*-amd64-server-*", "description": "Canonical, Ubuntu, 20.04 LTS, amd64 focal image", "owner": "099720109477" }, "ubuntu22": { "ami_name_filter": "ubuntu/images/hvm-ssd/ubuntu-*22*-amd64-server-*", "description": "Canonical, Ubuntu, 22.04 LTS, amd64 focal image", "owner": "099720109477" }, "windows2022": { "ami_name_filter": "Windows_Server-2022-English-Full-Base-*", "description": "Microsoft Windows Server 2022 Full Locale English AMI", "owner": "801119661308" } }``` | no |
| site_id | ArcGIS Enterprise site Id | `string` | `"arcgis-enterprise"` | no |
<!-- END_TF_DOCS -->