#!/bin/bash

# This script builds container image for Enterprise Admin CLI and pushes it to
# private ECR repository in the AWS region.
#
# On the machine where the script is executed:
#
# * AWS CLI and Docker must be installed
# * AWS credentials must be configured for AWS CLI
# * AWS region must be specified by AWS_DEFAULT_REGION environment variable

set -e

ECR_REPOSITORY_NAME=$1
BUILD_CONTEXT_PATH=$2
TAG=0.1.0

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REGISTRY_URL=$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com
IMAGE_TAG=$ECR_REGISTRY_URL/$ECR_REPOSITORY_NAME:$TAG

aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $ECR_REGISTRY_URL

set +e

aws ecr describe-repositories --repository-names $ECR_REPOSITORY_NAME

# Create ECR repository if it does not exist   
if [ $? -ne 0 ]
then
    aws ecr create-repository --repository-name $ECR_REPOSITORY_NAME --image-scanning-configuration scanOnPush=true --image-tag-mutability IMMUTABLE
    echo "ECR repository '${ECR_REPOSITORY_NAME}' created."
else
    echo "ECR repository '${ECR_REPOSITORY_NAME}' already exists."
fi    

aws ecr describe-images --repository-name $ECR_REPOSITORY_NAME --image-ids imageTag=$TAG

# Copy image to the ECR repository if it does not exist
if [[ $? == 0 ]]; then
    echo "Image $ECR_REPOSITORY_NAME:$TAG is already in the ECR repository"
else
    set -e
    
    docker build -t $IMAGE_TAG $BUILD_CONTEXT_PATH
    docker push $IMAGE_TAG

    echo "Image $ECR_REPOSITORY_NAME:$TAG copied."
fi