# Python Scripts

The Terraform modules and Packer templates use python scripts to invoke AWS and ArcGIS web services.

The scripts require Python 3.8 or later with [AWS SDK for Python (Boto3)](https://aws.amazon.com/sdk-for-python/) package installed.

The scripts retrieve AWS credentials and region from environment variables:

* AWS_ACCESS_KEY_ID - an AWS access key associated with an AWS IAM account
* AWS_SECRET_ACCESS_KEY - the secret key associated with the access key
* AWS_DEFAULT_REGION - code of the default AWS region

## downloads_api

My Esri Downloads API repository client.

## publish_artifact

Retrieves AMI Id from packer-manifest.json file and saves in SSM parameter.

usage:

```shell
python -m publish_artifact [-h] [-p PARAMETER] [-f MANIFEST] [-r PACKER_RUN_UUID]
```

options:

```shell
  -h, --help          show this help message and exit
  -p PARAMETER        SSM parameter name
  -f MANIFEST         packer-manifest.json file path
  -r PACKER_RUN_UUID  Packer run UUID
```

## s3_copy_files

Copies files from local file system, public URLs, and, My Esri repository to S3 bucket.

usage:

```shell
python -m s3_copy_files [-h] [-b BUCKET_NAME] [-u USERNAME] [-p PASSWORD] -f FILES
```

options:

```shell
  -h, --help      show this help message and exit
  -b BUCKET_NAME  S3 bucket name
  -u USERNAME     My Esri user name
  -p PASSWORD     My Esri user password
  -f FILES        Index JSON file path
```

My Esri credentials can alo be specified with environment variables:

* ARCGIS_ONLINE_USERNAME - My Esri user name
* ARCGIS_ONLINE_PASSWORD - My Esri user password

Refer to the [repository index JSON file format](./index_json_file_format.md) for the JSON file specification.

## ssm_bootstrap

Runs `<site id>-bootstrap` SSM command on EC2 instances in a deployment with specified roles.

usage:

```shell
python -m ssm_bootstrap [-h] [-s SITE_ID] [-d DEPLOYMENT_ID] [-m MACHINE_ROLES] [-c CHEF_CLIENT_URL] [-k CHEF_COOKBOOKS_URL] [-b S3_BUCKET]
```

options:

```shell
  -h, --help            show this help message and exit
  -s SITE_ID            ArcGIS Enterprise site Id
  -d DEPLOYMENT_ID      ArcGIS Enterprise deployment Id
  -m MACHINE_ROLES      Machine roles
  -c CHEF_CLIENT_URL    Chef client URL
  -k CHEF_COOKBOOKS_URL Chef cookbooks URL
  -b S3_BUCKET          Output S3 bucket
```

## ssm_clean_up

Runs `<site id>-clean-up` SSM command on EC2 instances of a deployment in certain roles.

usage:

```shell
python -m ssm_clean_up [-h] [-s SITE_ID] [-d DEPLOYMENT_ID] [-m MACHINE_ROLES] [-p SYSPREP] [-u UNINSTALL_CHEF_CLIENT] [-f DIRECTORIES] [-b S3_BUCKET]
```

options:

```shell
  -h, --help            show this help message and exit
  -s SITE_ID            ArcGIS Enterprise site Id
  -d DEPLOYMENT_ID      ArcGIS Enterprise deployment Id
  -m MACHINE_ROLES      Machine roles
  -p SYSPREP            Run sysprep script
  -u UNINSTALL_CHEF_CLIENT
                        Uninstall Chef/Cinc Client
  -f DIRECTORIES        Comma-separated list of local directories to clean up
  -b S3_BUCKET          Output S3 bucket
```

## ssm_cloudwatch_config

Runs AmazonCloudWatch-ManageAgent SSM command on all EC2 instances in a deployment.

usage:

```shell
python -m ssm_cloudwatch_config [-h] [-s SITE_ID] [-d DEPLOYMENT_ID] [-p PARAMETER] [-b S3_BUCKET]
```

options:

```shell
  -h, --help        show this help message and exit
  -s SITE_ID        ArcGIS Enterprise site Id
  -d DEPLOYMENT_ID  ArcGIS Enterprise deployment Id
  -p PARAMETER      SSM parameter name with CloudWatch agent configuration JSON
  -b S3_BUCKET      Output S3 bucket
```

## ssm_install_awscli

Runs `<site id>-install-awscli` SSM command on EC2 instances in a deployment with specified roles.

usage:

```shell
python -m ssm_install_awscli [-h] [-s SITE_ID] [-d DEPLOYMENT_ID] [-m MACHINE_ROLES] [-b S3_BUCKET]
```

options:

```shell
  -h, --help        show this help message and exit
  -s SITE_ID        ArcGIS Enterprise site Id
  -d DEPLOYMENT_ID  ArcGIS Enterprise deployment Id
  -m MACHINE_ROLES  Machine roles
  -b S3_BUCKET      Output S3 bucket
```

## ssm_nfs_mount

Runs `<site id>-nfs-mount` SSM command on EC2 instances in a deployment with specified roles.

usage:

```shell
python -m ssm_bootstrap [-h] [-s SITE_ID] [-d DEPLOYMENT_ID] [-m MACHINE_ROLES] [-a FILE_SYSTEM_DNS] [-p MOUNT_POINT] [-b S3_BUCKET]
```

options:

```shell
  -h, --help          show this help message and exit
  -s SITE_ID          ArcGIS Enterprise site Id
  -d DEPLOYMENT_ID    ArcGIS Enterprise deployment Id
  -m MACHINE_ROLES    Machine roles
  -a FILE_SYSTEM_DNS  File system DNS
  -p MOUNT_POINT      Mount point
  -b S3_BUCKET        Output S3 bucket
```

## ssm_package

Runs AWS-ConfigureAWSPackage SSM command on EC2 instances in a deployment with specified roles.

usage:

```shell
python -m ssm_package [-h] [-s SITE_ID] [-d DEPLOYMENT_ID] [-m MACHINE_ROLES] [-p PACKAGE] [-v VERSION] [-b S3_BUCKET]
```

options:

```shell
  -h, --help        show this help message and exit
  -s SITE_ID        ArcGIS Enterprise site Id
  -d DEPLOYMENT_ID  ArcGIS Enterprise deployment Id
  -m MACHINE_ROLES  Machine roles
  -p PACKAGE        AWS Package Manager package name
  -v VERSION        AWS Package Manager package version
  -b S3_BUCKET      Output S3 bucket
```

## ssm_run_chef

The script runs Chef Client in solo mode on EC2 instances of a deployment.

The script retrieves the Chef JSON attributes from the JSON_ATTRIBUTES environment variable and puts them into SecureString SSM parameter specified by json_attributes_parameter command line argument. To execute Chef Client the script runs `<site id>-run-chef` SSM command on EC2 instances of the deployment in the specified machine roles, waits for all the command invocations to complete, retrieves from S3 and prints outputs of the command invocations.

usage:

```shell
python -m ssm_run_chef [-h] [-s SITE_ID] [-d DEPLOYMENT_ID] [-m MACHINE_ROLES] [-j JSON_ATTRIBUTES_PARAMETER] [-b S3_BUCKET] [-e EXECUTION_TIMEOUT]
```

options:

```shell
  -h, --help            show this help message and exit
  -s SITE_ID            Site Id
  -d DEPLOYMENT_ID      Deployment Id
  -m MACHINE_ROLES      Machine roles
  -j JSON_ATTRIBUTES_PARAMETER
                        SSM parameter name of role attributes
  -b S3_BUCKET          Output S3 bucket
  -e EXECUTION_TIMEOUT  Execution timeout (seconds)
```

## ssm_utils

Helper functions used by scripts that run SSM commands:

* wait_for_target_instances() - Wait until the target EC2 instances status is 'online'.
* wait_for_command_invocations() - Wait for the command invocations to complete.
* print_command_output() - Retrieve from S3 and prints outputs of the command invocations.

## token_service_client

ArcGIS Online token service client.
