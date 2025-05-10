#!/bin/bash
set -euo pipefail

# Configuration
PROJECT_ID="terraform-inf"
SERVICE_ACCOUNT="terraform-gcp-pipeline@terraform-inf.iam.gserviceaccount.com"
REGION="us-central1"
IMAGE_NAME="iris-api"
REPO_NAME="docker-repo"

# Authenticate user
echo -e "\033[1;32mAuthenticating with user credentials...\033[0m"
gcloud auth login --brief

# Enable required APIs
echo -e "\033[1;32mEnabling necessary GCP APIs...\033[0m"
gcloud services enable \
  artifactregistry.googleapis.com \
  run.googleapis.com \
  composer.googleapis.com \
  dataflow.googleapis.com \
  bigquery.googleapis.com \
  compute.googleapis.com \
  monitoring.googleapis.com \
  serviceusage.googleapis.com \
  --project="${PROJECT_ID}"

# Build and push Docker image
echo -e "\033[1;32mBuilding and pushing Docker image...\033[0m"
pushd api > /dev/null
gcloud auth configure-docker "${REGION}-docker.pkg.dev"
docker build -t "${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/${IMAGE_NAME}:latest" .
docker push "${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/${IMAGE_NAME}:latest"
popd > /dev/null

# Terraform deployment
echo -e "\033[1;32mDeploying infrastructure with Terraform...\033[0m"
terraform init -reconfigure \
  -backend-config="bucket=gcp-state-terraform" \
  -backend-config="prefix=terraform/state"

terraform apply \
  -var="project_id=${PROJECT_ID}" \
  -var="service_account_email=${SERVICE_ACCOUNT}" \
  -auto-approve

echo -e "\033[1;32mDeployment completed successfully!\033[0m"
