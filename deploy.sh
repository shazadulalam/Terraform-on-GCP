#!/bin/bash
set -euo pipefail

# This script automates the deployment of the application and infrastructure.
#
# Prerequisites:
# 1. Google Cloud SDK (`gcloud`) installed and configured.
# 2. Terraform installed.
# 3. Docker installed.
# 4. You must be authenticated with GCP: run `gcloud auth login --brief`
#    For non-interactive environments (CI/CD), ensure a service account is configured.
# 5. The `terraform/terraform.tfvars` file must be created and populated with your
#    specific GCP project_id, region, service_account_email, container_image, etc.
#    Refer to `terraform/terraform.tfvars.example` for the required variables.
# 6. The GCS bucket for Terraform state (specified in `terraform/backend.tf`)
#    must exist. You might need to update `terraform/backend.tf` with your bucket name.

echo -e "\033[1;34mStarting Deployment Process...\033[0m"

# ------------------------------------------------------------------------------
# Configuration (User-defined - ensure these are set if not using terraform.tfvars for these specific script actions)
# These variables are primarily for the Docker build and push steps.
# Terraform variables should be set in terraform/terraform.tfvars
# ------------------------------------------------------------------------------
# Attempt to source variables from a .env file in the root if it exists
if [ -f .env ]; then
  echo -e "\033[1;33mSourcing environment variables from .env file...\033[0m"
  export $(grep -v '^#' .env | xargs)
fi

# Variables needed for Docker build/push. These can be set as environment variables
# or manually defined here if not in .env.
# Ensure these match what you'd use in terraform.tfvars for 'container_image' components.
GCP_PROJECT_ID="${GCP_PROJECT_ID:-}" # Example: your-gcp-project-id
GCP_REGION="${GCP_REGION:-us-central1}"    # Example: us-central1
DOCKER_REPO_NAME="${DOCKER_REPO_NAME:-docker-repo}" # Example: docker-repo (must match terraform var 'repository_name')
IMAGE_NAME="${IMAGE_NAME:-iris-api}"        # Example: iris-api

# Check if essential variables for Docker are set
if [ -z "$GCP_PROJECT_ID" ]; then
    echo -e "\033[1;31mError: GCP_PROJECT_ID is not set. Please set it in your environment or .env file.\033[0m"
    exit 1
fi

echo -e "\033[1;32mUsing configuration for Docker:\033[0m"
echo "GCP Project ID: ${GCP_PROJECT_ID}"
echo "GCP Region: ${GCP_REGION}"
echo "Docker Repository Name: ${DOCKER_REPO_NAME}"
echo "Image Name: ${IMAGE_NAME}"
echo ""
echo -e "\033[1;33mImportant: Ensure your terraform/terraform.tfvars file is correctly configured with all necessary variables including project_id, region, service_account_email, and container_image (which should match the one built below).\033[0m"
echo -e "\033[1;33mThe container_image in terraform.tfvars should be: ${GCP_REGION}-docker.pkg.dev/${GCP_PROJECT_ID}/${DOCKER_REPO_NAME}/${IMAGE_NAME}:latest\033[0m"
read -p "Press [Enter] to continue if your terraform.tfvars is ready, or Ctrl+C to abort."

# Authenticate user (if not already authenticated)
echo -e "\033[1;32mAuthenticating with user credentials (if needed)...\033[0m"
gcloud auth login --brief
gcloud config set project ${GCP_PROJECT_ID}

# Enable required APIs
echo -e "\033[1;32mEnabling necessary GCP APIs for project ${GCP_PROJECT_ID}...\033[0m"
gcloud services enable \
  artifactregistry.googleapis.com \
  run.googleapis.com \
  composer.googleapis.com \
  dataflow.googleapis.com \
  bigquery.googleapis.com \
  compute.googleapis.com \
  monitoring.googleapis.com \
  serviceusage.googleapis.com \
  cloudresourcemanager.googleapis.com \
  iam.googleapis.com \
  --project="${GCP_PROJECT_ID}"

# Build and push Docker image
echo -e "\033[1;32mBuilding and pushing Docker image...\033[0m"
echo -e "\033[1;33mRunning Docker commands from project root. API code is in ./api/\033[0m"
gcloud auth configure-docker "${GCP_REGION}-docker.pkg.dev" --project="${GCP_PROJECT_ID}"
docker build -t "${GCP_REGION}-docker.pkg.dev/${GCP_PROJECT_ID}/${DOCKER_REPO_NAME}/${IMAGE_NAME}:latest" ./api
docker push "${GCP_REGION}-docker.pkg.dev/${GCP_PROJECT_ID}/${DOCKER_REPO_NAME}/${IMAGE_NAME}:latest"

# Terraform deployment
echo -e "\033[1;32mChanging to terraform directory: ./terraform\033[0m"
pushd terraform > /dev/null

echo -e "\033[1;32mInitializing Terraform...\033[0m"
echo -e "\033[1;33mEnsure 'terraform/backend.tf' is configured with your GCS bucket for state.\033[0m"
terraform init -reconfigure

echo -e "\033[1;32mApplying Terraform configuration...\033[0m"
echo -e "\033[1;33mTerraform will use variables from 'terraform.tfvars' (if it exists and is populated).\033[0m"
terraform apply -auto-approve

popd > /dev/null # Return to the root directory

echo -e "\033[1;32mDeployment completed successfully!\033[0m"
echo -e "\033[1;33mThe container_image variable in your terraform.tfvars should have been set to: ${GCP_REGION}-docker.pkg.dev/${GCP_PROJECT_ID}/${DOCKER_REPO_NAME}/${IMAGE_NAME}:latest\033[0m"
