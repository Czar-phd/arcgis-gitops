#!/bin/bash

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

# This script copies ArcGIS Enterprise for Kubernetes images from DockerHub 
# registry to private Amazon ECR repositories.
#
# Required environment variables:
# CONTAINER_REGISTRY_ORG - The container registry organization
# CONTAINER_REGISTRY_USER - The container registry username
# CONTAINER_REGISTRY_PASSWORD - The container registry password
# AWS_DEFAULT_REGION - The AWS default region
# ECR_REPOSITORY_PREFIX - The ECR repository prefix (a.k.a. namespace)

set -e

MANIFEST_PATH=$1
ARCGIS_VERSION=$2
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REGISTRY_URL=$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com

# Log in to the container registry and ECR
echo $CONTAINER_REGISTRY_PASSWORD | docker login --username $CONTAINER_REGISTRY_USER --password-stdin
aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $ECR_REGISTRY_URL

# Get the list of images from the version manifest file
full_cmd="cat $MANIFEST_PATH | jq -r '.versions[] | select(.version==\"$ARCGIS_VERSION\") | .containers[].image' | sort | uniq"
IMAGE_LIST=$(eval $full_cmd)
num=$(echo $IMAGE_LIST | wc -w)

echo "Found $num images."
echo "Copying images from DockerHub org $CONTAINER_REGISTRY_ORG to $ECR_REGISTRY_URL..."

for REPO_WITH_TAG in $IMAGE_LIST
do
    REPO=$(echo $REPO_WITH_TAG | cut -d: -f1)
    TAG=$(echo $REPO_WITH_TAG | cut -d: -f2)

    REPOSITORY_NAME=$CONTAINER_REGISTRY_ORG/$REPO
    ECR_REPOSITORY_NAME=$ECR_REPOSITORY_PREFIX/$REPOSITORY_NAME
    IMAGE=$ECR_REGISTRY_URL/$ECR_REPOSITORY_NAME:$TAG

    set +e
    
    aws ecr describe-repositories --repository-names "${ECR_REPOSITORY_NAME}" > /dev/null 2>&1

    # Create ECR repository if it does not exist   
    if [ $? -ne 0 ]
    then
        aws ecr create-repository --repository-name "${ECR_REPOSITORY_NAME}" --image-scanning-configuration scanOnPush=true --image-tag-mutability IMMUTABLE
        echo "ECR repository '${ECR_REPOSITORY_NAME}' created."
    else
        echo "ECR repository '${ECR_REPOSITORY_NAME}' already exists."
    fi    

    aws ecr describe-images --repository-name $ECR_REPOSITORY_NAME --image-ids imageTag=$TAG > /dev/null 2>&1

    # Copy image to the ECR repository if it does not exist
    if [[ $? == 0 ]]; then
        echo "Image $ECR_REPOSITORY_NAME:$TAG is already in the ECR repository"
    else
        set -e

        docker pull -q $REPOSITORY_NAME:$TAG

        docker tag $REPOSITORY_NAME:$TAG $IMAGE

        docker push -q $IMAGE

        docker rmi $REPOSITORY_NAME:$TAG  $IMAGE > /dev/null 2>&1

        echo "Image $ECR_REPOSITORY_NAME:$TAG copied."
    fi
done
