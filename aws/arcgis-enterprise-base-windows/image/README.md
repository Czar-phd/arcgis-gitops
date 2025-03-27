# Packer Template for Base ArcGIS Enterprise on Windows AMIs

The Packer templates builds "main" and "fileserver" EC2 AMIs for a specific base ArcGIS Enterprise deployment.

The AMIs are built from a Windows OS base image specified by SSM parameter "/arcgis/${var.site_id}/images/${var.os}".

The template first copies installation media for the ArcGIS Enterprise version and required third party dependencies from My Esri and public repositories to the private repository S3 bucket. The files to copy are specified in ../manifests/arcgis-enterprise-s3files-${var.arcgis_version}.json index file.

Then the template uses python scripts to run SSM commands on the source EC2 instances.

On "main" instance:

1. Install AWS CLI
2. Install CloudWatch Agent
3. Install Cinc Client and Chef Cookbooks for ArcGIS
4. Download setups from the private repository S3 bucket.
5. Install base ArcGIS Enterprise applications
6. Install patches for the base ArcGIS Enterprise applications
7. Delete unused files, uninstall Cinc Client, run sysprep

On "fileserver" instance:

1. Install AWS CLI
2. Install CloudWatch Agent
3. Delete unused files, uninstall Cinc Client, run sysprep

IDs of the AMIs are saved in "/arcgis/${var.site_id}/images/${var.deployment_id}/fileserver", "/arcgis/${var.site_id}/images/${var.deployment_id}/primary", and "/arcgis/${var.site_id}/images/${var.deployment_id}/standby" SSM parameters.

## Requirements

On the machine where Packer is executed:

* Python 3.8 or later with [AWS SDK for Python (Boto3)](https://aws.amazon.com/sdk-for-python/) package must be installed
* Path to aws/scripts directory must be added to PYTHONPATH
* AWS credentials must be configured.
* My Esri user name and password must be specified either using environment variables ARCGIS_ONLINE_USERNAME and ARCGIS_ONLINE_PASSWORD or the input variables.

## SSM Parameters

The template uses the following SSM parameters:

| SSM parameter name | Description |
|--------------------|-------------|
| /arcgis/${var.site_id}/chef-client-url/${var.os} | Chef Client URL |
| /arcgis/${var.site_id}/cookbooks-url | Chef Cookbooks for ArcGIS archive URL |
| /arcgis/${var.site_id}/iam/instance-profile-name | IAM instance profile name|
| /arcgis/${var.site_id}/images/${var.os} | Source AMI Id|
| /arcgis/${var.site_id}/s3/logs | S3 bucket for SSM commands output |
| /arcgis/${var.site_id}/s3/region | S3 buckets region code |
| /arcgis/${var.site_id}/s3/repository | Private repository S3 bucket |
| /arcgis/${var.site_id}/vpc/subnets | Ids of VPC subnets |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| aws_region | AWS region Id | `string` | `env("AWS_DEFAULT_REGION")` | no |
| arcgis_data_store_patches |File names of ArcGIS Data Store patches to install | `string` | `[]` | no |
| arcgis_portal_patches | File names of Portal for ArcGIS patches to install | `string` | `[]` | no |
| arcgis_server_patches | File names of ArcGIS Server patches to install | `string` | `[]` | no |
| arcgis_version | ArcGIS Enterprise version | `string` | `"11.4"` | no |
| arcgis_web_adaptor_patches | File names of ArcGIS Web Adaptor patches to install | `string` | `[]` | no |
| deployment_id | Deployment Id | `string` | `"enterprise-base-windows"` | no |
| instance_type | EC2 instance type | `string` | `"6i.xlarge"` | no |
| os | Operating system Id | `string` | `"windows2022"` | no |
| portal_web_context | Portal for ArcGIS web context | `string` | `"portal"` | no |
| root_volume_size | Root EBS volume size in GB | `number` | `100` | no |
| run_as_password | Password for the account used to run ArcGIS Server, Portal for ArcGIS, and ArcGIS Data Store. | `string` | | yes |
| run_as_user | User account used to run ArcGIS Server, Portal for ArcGIS, and ArcGIS Data Store. | `string` | `"arcgis"` | no |
| server_web_context | ArcGIS Server web context | `string` | `"server"` | no |
| site_id | ArcGIS Enterprise site Id | `string` | `"arcgis"` | no |
| skip_create_ami | If true, Packer will not create the AMI | `bool` | `false` | no |
