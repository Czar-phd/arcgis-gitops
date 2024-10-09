<!-- BEGIN_TF_DOCS -->
# Restore Terraform Module for Base ArcGIS Enterprise on Windows

The Terraform module restores from backup base ArcGIS Enterprise deployment on Windows platform.

The module runs WebGISDR utility with 'import' option on primary EC2 instance of the deployment.

## Requirements

The base ArcGIS Enterprise must be configured on the deployment by application terraform module for base ArcGIS Enterprise on Windows.

On the machine where Terraform is executed:

* Python 3.8 or later with [AWS SDK for Python (Boto3)](https://aws.amazon.com/sdk-for-python/) package must be installed
* Path to aws/scripts directory must be added to PYTHONPATH
* AWS credentials must be configured

## SSM Parameters

The module uses the following SSM parameters:

| SSM parameter name | Description |
|--------------------|-------------|
| /arcgis/${var.site_id}/s3/backup | Backup S3 bucket |
| /arcgis/${var.site_id}/s3/logs | S3 bucket for SSM command output |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 5.22 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| arcgis_enterprise_webgisdr_import | ../../modules/run_chef | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_ssm_parameter.s3_backup](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| admin_password | Portal for ArcGIS administrator user password | `string` | n/a | yes |
| admin_username | Portal for ArcGIS administrator user name | `string` | `"siteadmin"` | no |
| aws_region | AWS region Id | `string` | n/a | yes |
| backup_restore_mode | Type of backup | `string` | `"backup"` | no |
| deployment_id | Deployment Id | `string` | `"arcgis-enterprise-base"` | no |
| execution_timeout | Execution timeout in seconds | `number` | `36000` | no |
| portal_admin_url | Portal for ArcGIS administrative URL | `string` | `"https://localhost:7443/arcgis"` | no |
| run_as_password | Password for the account used to run Portal for ArcGIS | `string` | n/a | yes |
| run_as_user | User name for the account used to run Portal for ArcGIS | `string` | `"arcgis"` | no |
| site_id | ArcGIS site Id | `string` | `"arcgis-enterprise"` | no |
<!-- END_TF_DOCS -->