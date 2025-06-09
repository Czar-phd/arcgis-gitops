<!-- BEGIN_TF_DOCS -->
# Infrastructure Terraform Module for base ArcGIS Enterprise on Windows

The Terraform module creates AWS resources for highly available base ArcGIS Enterprise deployment on Windows platform.

![Base ArcGIS Enterprise on Windows / Infrastructure](arcgis-enterprise-base-windows-infrastructure.png "Base ArcGIS Enterprise on Windows / Infrastructure")

The module launches two (or one, if "is_ha" input variable is set to false) SSM managed EC2 instances in the private VPC subnets or subnets specified by "subnet_ids" input variable.
The EC2 instances are launched from images retrieved from "/arcgis/${var.site_id}/images/${var.deployment_id}/{instance role}" SSM parameters.
The images must be created by the Packer Template for Base ArcGIS Enterprise on Windows.

For the EC2 instances the module creates "A" records in the VPC Route53 private hosted zone to make the instances addressable using permanent DNS names.

> Note that the EC2 instance will be terminated and recreated if the infrastructure terraform module is applied again after the SSM parameter value was modified by a new image build.

S3 buckets for the portal content and object store are created. The S3 buckets names are stored in the SSM parameters.

The module creates an Application Load Balancer (ALB) with listeners for ports 80, 443, 6443, and 7443 and target groups for the listeners that target the EC2 instances.
Internet-facing load balancer is configured to use two of the public VPC subnets, while internal load balancer uses the private subnets.
The module also creates a private Route53 hosted zone for the deployment FQDN and an alias A record for the load balancer DNS name in the hosted zone.
This makes the deployment FQDN addressable from the VPC subnets.  

The deployment's Monitoring Subsystem consists of:

* An SNS topic and a CloudWatch alarms that monitor the target groups and post to the SNS topic if the number of unhealthy instances in nonzero.
* A CloudWatch log group
* CloudWatch agent on the EC2 instances that sends the system and Chef run logs to the log group as well as memory and disk utilization on the EC2 instances.
* A CloudWatch dashboard that displays the CloudWatch alerts, metrics, and logs of the deployment.

All the created AWS resources are tagged with ArcGISSiteId and ArcGISDeploymentId tags.

## Requirements

On the machine where Terraform is executed:

* Python 3.8 or later with [AWS SDK for Python (Boto3)](https://aws.amazon.com/sdk-for-python/) package must be installed
* Path to aws/scripts directory must be added to PYTHONPATH
* AWS credentials must be configured

Before creating the infrastructure, an SSL certificate for the base ArcGIS Enterprise deployment domain name
must be imported into or issued by AWS Certificate Manager service in the AWS account. The certificate's
ARN specified by "ssl_certificate_arn" input variable will be used to configure HTTPS listeners of the load balancer.

After creating the infrastructure, the deployment FQDN also must be pointed to the DNS name of Application Load Balancer
exported by "alb_dns_name" output value of the module.

## Troubleshooting

Use Session Manager connection in AWS Console for SSH access to the EC2 instances.

The SSM commands output stored in the logs S3 bucket is copied in the Terraform stdout.

## SSM Parameters

The module reads the following SSM parameters:

| SSM parameter name | Description |
|--------------------|-------------|
| /arcgis/${var.site_id}/iam/instance-profile-name | IAM instance profile name |
| /arcgis/${var.site_id}/images/${var.deployment_id}/primary | Primary EC2 instance AMI Id |
| /arcgis/${var.site_id}/images/${var.deployment_id}/standby | Standby EC2 instance AMI Id |
| /arcgis/${var.site_id}/s3/logs | S3 bucket for SSM commands output |
| /arcgis/${var.site_id}/vpc/subnets | Ids of VPC subnets |
| /arcgis/${var.site_id}/vpc/hosted-zone-id | VPC hosted zone Id |
| /arcgis/${var.site_id}/vpc/id | VPC Id |

The module writes the following SSM parameters:

| SSM parameter name | Description |
|--------------------|-------------|
| /arcgis/${var.site_id}/${var.deployment_id}/security-group-id | Deployment security group Id |
| /arcgis/${var.site_id}/${var.deployment_id}/sns-topic-arn | ARN of SNS topic for deployment alarms |
| /arcgis/${var.site_id}/${var.deployment_id}/content-s3-bucket | Portal for ArcGIS content store S3 bucket |
| /arcgis/${var.site_id}/${var.deployment_id}/object-store-s3-bucket | Object store S3 bucket |
 | /arcgis/${var.site_id}/${var.deployment_id}/portal-web-context | Portal for ArcGIS web context |
| /arcgis/${var.site_id}/${var.deployment_id}/server-web-context | ArcGIS Server web context |
| /arcgis/${var.site_id}/${var.deployment_id}/alb/arn | ARN of the application load balancer |
| /arcgis/${var.site_id}/${var.deployment_id}/alb/dns-name | DNS name of the application load balancer |
| /arcgis/${var.site_id}/${var.deployment_id}/alb/security-group-id | Security group Id of the application load balancer |
| /arcgis/${var.site_id}/${var.deployment_id}/deployment-fqdn | Fully qualified domain name of the deployment |
| /arcgis/${var.site_id}/${var.deployment_id}/deployment-url | Portal for ArcGIS URL of the deployment |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 5.22 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| alb | ../../modules/alb | n/a |
| cw_agent | ../../modules/cw_agent | n/a |
| dashboard | ../../modules/dashboard | n/a |
| portal_https_alb_target | ../../modules/alb_target_group | n/a |
| security_group | ../../modules/security_group | n/a |
| server_https_alb_target | ../../modules/alb_target_group | n/a |
| site_core_info | ../../modules/site_core_info | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_instance.primary](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_instance.standby](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_network_interface.primary](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_interface) | resource |
| [aws_network_interface.standby](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_interface) | resource |
| [aws_route53_record.primary](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.standby](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_s3_bucket.object_store](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket.portal_content](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_ssm_parameter.deployment_url](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.object_store_s3_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.portal_content_s3_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.portal_web_context](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.security_group_id](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.server_web_context](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ami.ami](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_ssm_parameter.primary_ami](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter) | data source |
| [aws_ssm_parameter.standby_ami](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| aws_region | AWS region Id | `string` | n/a | yes |
| client_cidr_blocks | Client CIDR blocks | `list(string)` | ```[ "0.0.0.0/0" ]``` | no |
| deployment_fqdn | Fully qualified domain name of the base ArcGIS Enterprise deployment | `string` | n/a | yes |
| deployment_id | ArcGIS Enterprise deployment Id | `string` | `"enterprise-base-windows"` | no |
| instance_type | EC2 instance type | `string` | `"m7i.2xlarge"` | no |
| internal_load_balancer | If true, the load balancer scheme is set to 'internal' | `bool` | `false` | no |
| is_ha | If true, the deployment is in high availability mode | `bool` | `true` | no |
| key_name | EC2 key pair name | `string` | n/a | yes |
| portal_web_context | Portal for ArcGIS web context | `string` | `"portal"` | no |
| root_volume_iops | Root EBS volume IOPS of primary and standby EC2 instances | `number` | `3000` | no |
| root_volume_size | Root EBS volume size in GB of primary and standby EC2 instances | `number` | `1024` | no |
| root_volume_throughput | Root EBS volume throughput in MB/s of primary and standby EC2 instances | `number` | `125` | no |
| server_web_context | ArcGIS Server web context | `string` | `"server"` | no |
| site_id | ArcGIS site Id | `string` | `"arcgis"` | no |
| ssl_certificate_arn | SSL certificate ARN for HTTPS listener of the load balancer | `string` | n/a | yes |
| ssl_policy | Security Policy that should be assigned to the ALB to control the SSL protocol and ciphers | `string` | `"ELBSecurityPolicy-TLS13-1-2-2021-06"` | no |
| subnet_ids | EC2 instances subnet IDs (by default, the first two private VPC subnets are used) | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| alb_dns_name | DNS name of application load balancer |
| deployment_url | Portal for ArcGIS URL of the deployment |
| security_group_id | EC2 security group Id |
<!-- END_TF_DOCS -->