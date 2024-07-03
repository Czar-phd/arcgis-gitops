/*
 * # Terraform module nfs_mount
 * 
 * Terraform module nfs_mount mounts an NFS target on EC2 instances in a deployment.
 *
 * The module uses ssm_nfs_mount.py script to run {var.site-id}-nfs-mount SSM command on the deployment's EC2 instances in specific roles.
 *
 * ## Requirements
 *
 * The S3 bucket for the SSM command output is retrieved from "/arcgis/{var.site_id}/s3/logs" SSM parameter.
 *
 * On the machine where Terraform is executed:
 *
 * * Python 3.8 or later with [AWS SDK for Python (Boto3)](https://aws.amazon.com/sdk-for-python/) package must be installed
 * * Path to aws/scripts directory must be added to PYTHONPATH
 * * AWS credentials must be configured
 * * AWS region must be specified by AWS_DEFAULT_REGION environment variable 
 */

# Copyright 2024 Esri
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

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.22"
    }
  }
}

data "aws_ssm_parameter" "output_s3_bucket" {
  name  = "/arcgis/${var.site_id}/s3/logs"
}

resource "null_resource" "nfs_mount" {
  triggers = {
    always_run = "${timestamp()}"
  }
    
  provisioner "local-exec" {
    command = "python -m ssm_nfs_mount -s ${var.site_id} -d ${var.deployment_id} -m ${join(",", var.machine_roles)} -a ${var.file_system_dns} -p ${var.mount_point} -b ${nonsensitive(data.aws_ssm_parameter.output_s3_bucket.value)}"
  }
}
