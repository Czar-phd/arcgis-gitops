# ArcGIS Server on Linux Deployment in AWS

This template provides GitHub Actions workflows for [ArcGIS Server deployment](https://enterprise.arcgis.com/en/server/latest/install/linux/welcome-to-the-arcgis-for-server-install-guide.htm) operations on Linux platforms.

The template supports both standalone and federated ArcGIS Server deployments. Optionally, the deployments may include ArcGIS Web Adaptor and use Application Load Balancer of base ArcGIS Enterprise deployments.

Supported ArcGIS Server versions:

* 11.4
* 11.5

Supported Linux distributions:

* Red Hat Enterprise Linux 9

Before running the template workflows:

1. Configure the GitHub repository settings as described in the [Instructions](../README.md#instructions) section.
2. Provision core AWS resources for ArcGIS Enterprise site using [arcgis-site-core](../arcgis-site-core/README.md) template.

To enable the template's workflows, copy the .yaml files from the template's `workflows` directory to `/.github/workflows` directory in `main` branch, commit the changes, and push the branch to GitHub.

> Refer to READMEs of the Terraform modules and Packer templates for descriptions of the configuration properties.

## Initial Deployment

Initial deployment of ArcGIS Server includes building images, provisioning AWS resources, configuring the applications, and testing the deployment web services.

![ArcGIS Server on Linux Configuration Flow](./arcgis-server-linux-flowchart.png)

### 1. Set GitHub Actions Secrets for the Site

If ArcGIS Server is deployed as a standalone server or federated with ArcGIS Enterprise on Kubernetes, set the primary ArcGIS Server site administrator credentials in the GitHub Actions secrets of the repository settings.

| Name                      | Description                                |
|---------------------------|--------------------------------------------|
| ENTERPRISE_ADMIN_USERNAME | ArcGIS Server administrator user name      |
| ENTERPRISE_ADMIN_PASSWORD | ArcGIS Server administrator user password  |
| ENTERPRISE_ADMIN_EMAIL    | ArcGIS Server administrator e-mail address |

> The ArcGIS Server administrator user name must be between 6 and 128 characters long and can consist only of uppercase and lowercase ASCII letters, numbers, and dots (.).

> The ArcGIS Server administrator user password must be between 8 and 128 characters long and can consist only of uppercase and lowercase ASCII letters, numbers, and dots (.).

### 2. Build Images

GitHub Actions workflow **server-linux-aws-image** creates EC2 AMIs for ArcGIS Server deployment.

The workflow uses: [image](image/README.md) Packer template with [image.vars.json](../../config/aws/arcgis-server-linux/image.vars.json) config file.

Required IAM policies:

* TerraformBackend (allows S3 operations required by Ansible SSM connection)
* ArcGISEnterpriseImage

Instructions:

1. Set "arcgis_server_patches" property to the lists of patch file names that must be installed on the images.
2. If ArcGIS Web Adaptor is required, set "use_webadaptor" property to `true` and "server_web_context" property to the Web Adaptor name.
3. Commit the changes to a Git branch and push the branch to GitHub.
4. Run server-linux-aws-image workflow using the branch.

> In the configuration files, "os" and "arcgis_version" properties values for the same deployment must match across all the configuration files of the deployment.

### 3. Provision AWS Resources

GitHub Actions workflow **server-linux-aws-infrastructure** creates AWS resources for ArcGIS Server deployment.

The workflow uses [infrastructure](infrastructure/README.md) Terraform template with [infrastructure.tfvars.json](../../config/aws/arcgis-server-linux/infrastructure.tfvars.json) config file.

Required IAM policies:

* TerraformBackend
* ArcGISEnterpriseInfrastructure

Workflow Inputs:

* terraform_command - Terraform command (apply|plan)

Workflow Outputs:

* alb_dns_name - DNS name of the application load balancer

Instructions:

1. Create an EC2 key pair in the selected AWS region and set "key_name" property to the key pair name. Save the private key in a secure location.
2. To add the deployment to the load balancer of a base ArcGIS Enterprise deployment, set "alb_deployment_id" property to the base deployment Id. Otherwise, set "deployment_fqdn" property to the ArcGIS Server deployment fully qualified domain name, provision or import SSL certificate for the domain name into AWS Certificate Manager service in the selected AWS region, and set "ssl_certificate_arn" property to the certificate ARN.
3. If required, change "instance_type" and "root_volume_size" properties to the required [EC2 instance type](https://aws.amazon.com/ec2/instance-types/) and root EBS volume size (in GB).
4. If ArcGIS Web Adaptor is used, set "use_webadaptor" property to `true` and "server_web_context" property to the Web Adaptor name.
5. Commit the changes to the Git branch and push the branch to GitHub.
6. Run server-linux-aws-infrastructure workflow using the branch.
7. If "alb_deployment_id" is not set, retrieve the DNS name of the load balancer created by the workflow and create a CNAME record for it within the DNS server of the ArcGIS Server domain name.

> Job outputs are not shown in the properties of completed GitHub Actions run. To retrieve the DNS name, check the run logs of "Terraform Apply" step or read it from "/arcgis/${var.site_id}/${var.deployment_id}/alb/dns-name" SSM parameter.

> When updating the infrastructure, first run the workflow with terraform_command=plan before running it with terraform_command=apply and check the logs to make sure that Terraform does not destroy and recreate critical AWS resources such as EC2 instances.

### 4. Configure Applications

GitHub Actions workflow **server-linux-aws-application** configures or upgrades ArcGIS Server on EC2 instances.

The workflow uses [application](application/README.md) Terraform template with [application.tfvars.json](../../config/aws/arcgis-server-linux/application.tfvars.json) config file.

Required IAM policies:

* TerraformBackend
* ArcGISEnterpriseApplication

Inputs:

* terraform_command - Terraform command (apply|plan)

Outputs:

* arcgis_server_url - ArcGIS Server URL

Instructions:

1. Add ArcGIS Server authorization file for the ArcGIS Server version to `config/authorization/<ArcGIS version>` directory of the repository and set "server_authorization_file_path" property to the file paths.
2. If ArcGIS Web Adaptor is used, set "use_webadaptor" property `true`.
3. If the ArcGIS Server needs to be federated with Portal for ArcGIS, set "server_role" and "server_functions" properties to the required server role and function. If the server does not share the load balancer with the base ArcGIS Enterprise deployment, set "portal_url" property to the Portal for ArcGIS URL. To federate the server with ArcGIS Enterprise on Kubernetes organization, set "portal_org_id" property to "0123456789ABCDEF", which is the default organization Id.
4. To install configure ArcGIS Server and Apache Tomcat use specific SSL certificates, set "keystore_file_path" and "keystore_file_password" properties to the certificates file path and password.
5. Commit the changes to the Git branch and push the branch to GitHub.
6. Run server-linux-aws-application workflow using the branch.

> '~/config/' paths is linked to the repository's /config directory. It's recommended to use /config directory for the configuration files.

### 5. Test ArcGIS Server Deployment

GitHub Actions workflow **server-linux-aws-test** tests ArcGIS Server deployment.

The workflow uses test-server-admin script from ArcGIS Enterprise Admin CLI to test accessibility of the ArcGIS Server admin URL. The server domain name and web context are retrieved from infrastructure.tfvars.json properties file and from SSM parameters.

Instructions:

1. Run server-linux-aws-test workflow using the branch.

## Backups and Disaster Recovery

The templates support application-level ArcGIS Server disaster recovery operations using backup and restore utilities.

### Create Backups

GitHub Actions workflow **server-linux-aws-backup** creates ArcGIS Server backups using [backup utility](https://enterprise.arcgis.com/en/server/latest/develop/linux/backup-utility.htm).

The workflow uses [backup](backup/README.md) Terraform template with [backup.tfvars.json](../../config/aws/arcgis-server-linux/backup.tfvars.json) config file.

Required IAM policies:

* TerraformBackend
* ArcGISEnterpriseApplication

Instructions:

1. Set "admin_username" and "admin_password" properties in backup.tfvars.json file to the server administrator user name and password respectively.
2. Commit the changes to the Git branch and push the branch to GitHub.
3. Run server-linux-aws-backup workflow using the branch.

> To meet the required recovery point objective (RPO), schedule runs of server-linux-aws-backup workflow by configuring 'schedule' event in server-linux-aws-backup.yaml file.

### Restore from Backups

GitHub Actions workflow **server-linux-aws-restore** restores ArcGIS Server from backup using [restore utility](https://enterprise.arcgis.com/en/server/latest/develop/linux/restore-utility.htm).

The workflow uses [restore](restore/README.md) Terraform template with [restore.tfvars.json](../../config/aws/arcgis-server-linux/restore.tfvars.json) config file.

Required IAM policies:

* TerraformBackend
* ArcGISEnterpriseApplication

Instructions:

1. Set "admin_username" and "admin_password" properties in restore.tfvars.json file to the server administrator user name and password respectively.
2. Commit the changes to the Git branch and push the branch to GitHub.
3. Run server-linux-aws-restore workflow using the branch.

### Create Snapshots and Restore from Snapshots

GitHub Actions workflow **server-linux-aws-snapshot** creates a system-level backup by creating AMIs from EC2 instances of ArcGIS Server deployment. The workflow the workflow retrieves site and deployment IDs from [image.vars.json](../../config/aws/arcgis-server-linux/image.vars.json) config file and runs snapshot_deployment Python script. The workflow requires ArcGISEnterpriseImage IAM policy.

The workflows overwrites the AMI IDs in SSM Parameter Store written there by server-linux-aws-image workflow. When necessary, the deployment can be rolled back to state captured in the snapshot by running server-linux-aws-infrastructure workflow.

> Running server-linux-aws-snapshot workflow causes a short downtime because it reboots the EC2 instances.

> The snapshot captures only the data on the EC2 instances that does not include the content of other storage services, such as EFS filesystems used by ArcGIS Server config store.

Since creating snapshots involves downtime and integrity of the data cannot be guaranteed if data in the storage services was updated after the snapshot creation, snapshots are not recommended for use as backups for active deployments. Snapshots should be created during planned downtime, after deactivating the deployment, and before applying system and application patches or other system-level updates.

> The snapshot creation time depends on the size and throughput of the root EBS volumes of the EC2 instances.

## In-Place Updates and Upgrades

GitHub Actions workflow server-linux-aws-application supports upgrade mode used to in-place patch or upgrade the ArcGIS Server applications on the EC2 instances. In the upgrade mode, the workflow copies the required patches and setups to the private repository S3 bucket and downloads them to the EC2 instances. If the ArcGIS Server version was changed, it installs the new version of ArcGIS Server and re-configures it.

Instructions:

1. Set "arcgis_server_patches" property in application.tfvars.json file to the lists of patch file names that must be installed on the EC2 instances.
2. Add ArcGIS Server authorization file for the new ArcGIS Server version to `config/authorization/<ArcGIS version>` directory of the repository and set "server_authorization_file_path" property in application.tfvars.json file to the file path.
3. Change "is_upgrade" property in application.tfvars.json file to `true`.
4. Commit the changes to the Git branch and push the branch to GitHub.
5. Run server-linux-aws-application workflow using the branch.

## Destroying Deployments

GitHub Actions workflow **server-linux-aws-destroy** destroys AWS resources created by server-linux-aws-image, server-linux-aws-snapshot, server-linux-aws-infrastructure and server-linux-aws-application workflows.

The workflow uses [infrastructure](infrastructure/README.md) and [application](application/README.md) Terraform templates with [infrastructure.tfvars.json](../../config/aws/arcgis-server-linux/infrastructure.tfvars.json) and [application.tfvars.json](../../config/aws/arcgis-server-linux/application.tfvars.json) config files.

Required IAM policies:

* TerraformBackend
* ArcGISEnterpriseDestroy

Instructions:

1. Run server-linux-aws-destroy workflow using the branch.

> server-linux-aws-destroy workflow does not delete the deployment's backups.

## Disconnected Environments

To prevent deployments from accessing the Internet, use "internal" subnets for EC2 instances. The internal subnets do not have public IP addresses and are routed only to VPC endpoints of certain AWS services in specific AWS region.

The disconnected deployments cannot access the system and application internet services such as ArcGIS Online, My Esri, Esri license server, package repositories, pollination services, and time services.

The application image builds run in "private" subnets that can access the internet. The image build installs SSM Agents, CloudWatch agents, AWS CLI, and system packages required by the applications. The application update and upgrade workflows use S3 VPC endpoint to access the private repository S3 bucket to get all the required files.

The disconnected deployments must use authorization files that do not require internet access to the Esri license server, such as Esri Secure License File (ESLF) or ECP file (.ecp).  
