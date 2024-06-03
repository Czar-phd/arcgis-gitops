# Packer Template for ArcGIS Server on Linux AMI

The Packer templates builds EC2 AMI for a specific ArcGIS Server Enterprise deployment.

The AMI is built from a Linux OS base image specified by SSM parameter "/arcgis/${var.site_id}/images/${var.os}".

> Note: If the base image does not have SSM Agent installed, it's installed using user data script.

The template first copies installation media for the ArcGIS Server version and required third party dependencies from My Esri and public repositories to the private repository S3 bucket. The files to be copied are  specified in ../manifests/arcgis-server-s3files-${var.arcgis_version}.json index file.

Then the template uses python scripts to run SSM commands on the source EC2 instance to:

1. Install AWS CLI
2. Install CloudWatch Agent
3. Download setups from the private repository S3 bucket.
4. Install ArcGIS Server
5. Install patches for ArcGIS Server

Id of the built AMI is saved in "/arcgis/${var.site_id}/images/${var.os}/${var.deployment_id}" SSM parameter.

## Requirements

On the machine where Packer is executed:

* Python 3.8 or later with [AWS SDK for Python (Boto3)](https://aws.amazon.com/sdk-for-python/) package must be installed
* Path to aws/scripts directory must be added to PYTHONPATH
* Ansible 2.16 or later must be installed
* arcgis.common and arcgis.server Ansible collections must be installed
* AWS credentials must be configured.

My Esri user name and password must be specified either using environment variables ARCGIS_ONLINE_USERNAME and ARCGIS_ONLINE_PASSWORD or the input variables.

## SSM Parameters

The template uses the following SSM parameters:

| SSM parameter name | Description |
|--------------------|-------------|
| /arcgis/${var.site_id}/iam/instance-profile-name | IAM instance profile name|
| /arcgis/${var.site_id}/images/${var.os} | Source AMI Id|
| /arcgis/${var.site_id}/s3/logs | S3 bucket for SSM commands output |
| /arcgis/${var.site_id}/s3/region | S3 buckets region code |
| /arcgis/${var.site_id}/s3/repository | Private repository S3 bucket |
| /arcgis/${var.site_id}/vpc/private-subnet-1 | Private VPC subnet Id|

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| arcgis_online_password | ArcGIS Online user password | `string` | null | no |
| arcgis_online_username | ArcGIS Online user name | `string` | null | no |
| arcgis_server_patches | File names of ArcGIS Server patches to install | `string` | `[]` | no |
| arcgis_version | ArcGIS Enterprise version | `string` | `"11.3"` | no |
| instance_type | EC2 instance type | `string` | `"6i.xlarge"` | no |
| os | Operating system | `string` | `"rhel8"` | no |
| root_volume_size | Root EBS volume size in GB | `number` | `100` | no |
| run_as_user | User account used to run ArcGIS Server, Portal for ArcGIS, and ArcGIS Data Store | `string` | `"arcgis"` | no |
| site_id | ArcGIS site Id | `string` | `"arcgis-enterprise"` | no |
| skip_create_ami | If true, Packer will not create the AMI | `bool` | `false` | no |
