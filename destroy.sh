#!/bin/bash
set -euo pipefail

# Configuration
PROJECT_ID="terraform-inf"
SERVICE_ACCOUNT="terraform-gcp-pipeline@terraform-inf.iam.gserviceaccount.com"
REGION="us-central1"
IMAGE_NAME="iris-api"
REPO_NAME="docker-repo"

# Get script directory (useful for relative Terraform paths, if needed)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Destroy Terraform infrastructure
echo -e "\033[1;31mDestroying infrastructure with Terraform...\033[0m"
terraform destroy \
  -var="project_id=${PROJECT_ID}" \
  -var="service_account_email=${SERVICE_ACCOUNT}" \
  -auto-approve

# Remove Docker image
echo -e "\033[1;31mRemoving Docker image from Artifact Registry...\033[0m"
IMAGE_PATH="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/${IMAGE_NAME}"

# Check if image exists before attempting deletion
if gcloud artifacts docker images list "${IMAGE_PATH}" --include-tags --quiet | grep -q "latest"; then
  gcloud artifacts docker images delete "${IMAGE_PATH}:latest" --quiet --delete-tags
else
  echo -e "\033[1;33mWarning: Image ${IMAGE_PATH}:latest not found, skipping deletion\033[0m"
fi

echo -e "\033[1;31mCleanup completed successfully!\033[0m"
