#!/bin/bash
set -euo pipefail

# This script automates the destruction of the application and infrastructure.
#
# Prerequisites:
# 1. Google Cloud SDK (`gcloud`) installed and configured.
# 2. Terraform installed.
# 3. Docker installed (for image deletion).
# 4. You must be authenticated with GCP: run `gcloud auth login --brief`
#    For non-interactive environments (CI/CD), ensure a service account is configured.
# 5. The `terraform/terraform.tfvars` file should exist and be populated with the
#    same values used during deployment, or Terraform will prompt for them.
#    Refer to `terraform/terraform.tfvars.example` for the required variables.
# 6. The GCS bucket for Terraform state (specified in `terraform/backend.tf`)
#    must exist and be accessible.

echo -e "\033[1;34mStarting Destruction Process...\033[0m"

# ------------------------------------------------------------------------------
# Configuration for Docker Image Deletion
# These variables are for the Docker image deletion step.
# Ensure these match the image that was deployed.
# ------------------------------------------------------------------------------
# Attempt to source variables from a .env file in the root if it exists
if [ -f .env ]; then
  echo -e "\033[1;33mSourcing environment variables from .env file...\033[0m"
  export $(grep -v '^#' .env | xargs)
fi

# Variables needed for Docker image deletion. These can be set as environment variables
# or manually defined here if not in .env.
GCP_PROJECT_ID="${GCP_PROJECT_ID:-}"      # Example: your-gcp-project-id
GCP_REGION="${GCP_REGION:-us-central1}"    # Example: us-central1
DOCKER_REPO_NAME="${DOCKER_REPO_NAME:-docker-repo}" # Example: docker-repo (must match terraform var 'repository_name')
IMAGE_NAME="${IMAGE_NAME:-iris-api}"        # Example: iris-api

# Check if essential variables for Docker are set
if [ -z "$GCP_PROJECT_ID" ]; then
    echo -e "\033[1;31mWarning: GCP_PROJECT_ID is not set. Docker image deletion might fail or target the wrong project if not configured via gcloud default.\033[0m"
    # It's a warning because gcloud might have a default project configured.
fi

echo -e "\033[1;32mUsing configuration for Docker image deletion (if image exists):\033[0m"
echo "GCP Project ID: ${GCP_PROJECT_ID:- (using gcloud default)}"
echo "GCP Region: ${GCP_REGION}"
echo "Docker Repository Name: ${DOCKER_REPO_NAME}"
echo "Image Name: ${IMAGE_NAME}"
echo ""
echo -e "\033[1;33mImportant: Ensure your terraform/terraform.tfvars file is correctly configured or Terraform will prompt for variable values.\033[0m"
read -p "Press [Enter] to continue the destruction process, or Ctrl+C to abort."

# Authenticate user (if not already authenticated)
echo -e "\033[1;32mAuthenticating with user credentials (if needed)...\033[0m"
gcloud auth login --brief
if [ -n "$GCP_PROJECT_ID" ]; then
  gcloud config set project ${GCP_PROJECT_ID}
fi


# Terraform destroy
echo -e "\033[1;31mChanging to terraform directory: ./terraform\033[0m"
pushd terraform > /dev/null

echo -e "\033[1;31mInitializing Terraform...\033[0m"
echo -e "\033[1;33mEnsure 'terraform/backend.tf' is configured with your GCS bucket for state.\033[0m"
terraform init -reconfigure

echo -e "\033[1;31mDestroying infrastructure with Terraform...\033[0m"
echo -e "\033[1;33mTerraform will use variables from 'terraform.tfvars' (if it exists and is populated) or prompt if not found.\033[0m"
terraform destroy -auto-approve

popd > /dev/null # Return to the root directory

# Remove Docker image from Artifact Registry
# This part is best-effort; if variables are not set, it might not find the image.
if [ -n "$GCP_PROJECT_ID" ] && [ -n "$GCP_REGION" ] && [ -n "$DOCKER_REPO_NAME" ] && [ -n "$IMAGE_NAME" ]; then
  IMAGE_PATH="${GCP_REGION}-docker.pkg.dev/${GCP_PROJECT_ID}/${DOCKER_REPO_NAME}/${IMAGE_NAME}"
  echo -e "\033[1;31mAttempting to remove Docker image ${IMAGE_PATH}:latest from Artifact Registry...\033[0m"
  
  # Configure gcloud for the specific project for artifact commands
  gcloud auth configure-docker "${GCP_REGION}-docker.pkg.dev" --project="${GCP_PROJECT_ID}"
  
  # Check if image exists before attempting deletion
  if gcloud artifacts docker images list "${IMAGE_PATH}" --include-tags --quiet --project="${GCP_PROJECT_ID}" | grep -q "latest"; then
    gcloud artifacts docker images delete "${IMAGE_PATH}:latest" --quiet --delete-tags --project="${GCP_PROJECT_ID}"
    echo -e "\033[1;32mDocker image ${IMAGE_PATH}:latest deleted.\033[0m"
  else
    echo -e "\033[1;33mWarning: Image ${IMAGE_PATH}:latest not found in project ${GCP_PROJECT_ID}, skipping deletion.\033[0m"
  fi
else
  echo -e "\033[1;33mWarning: Insufficient configuration (GCP_PROJECT_ID, GCP_REGION, DOCKER_REPO_NAME, IMAGE_NAME) to delete Docker image. Skipping.\033[0m"
fi

echo -e "\033[1;31mDestruction process completed.\033[0m"
