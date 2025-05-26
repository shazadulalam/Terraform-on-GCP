# Terraform-on-GCP: Iris Prediction API and ETL

This project deploys a Python-based Iris classification API and an associated ETL pipeline (simulated using BigQuery) on Google Cloud Platform using Terraform. It demonstrates modular Terraform configurations, CI/CD with GitHub Actions, and a Clean Architecture pattern for the API.

## Table of Contents

- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Setup](#setup)
- [Deployment](#deployment)
- [API Usage](#api-usage)
- [ETL Information](#etl-information)
- [Destroying Infrastructure](#destroying-infrastructure)
- [Development](#development)

## Architecture

### Cloud Services
*   **Google Cloud Run:** Hosts the containerized Python FastAPI application.
*   **Google Cloud Composer:** Orchestrates ETL workflows (demonstrated with a BigQuery data load).
*   **Google BigQuery:** Used as a data warehouse, populated by the ETL DAG.
*   **Google Cloud Storage:** Used for Terraform state backend and potentially other storage needs.
*   **Google Artifact Registry:** Stores the Docker container image for the API.
*   **Google Cloud Monitoring:** (Assumed, as a monitoring module exists) Provides monitoring for deployed resources.
*   **Google Cloud Dataflow:** (Module exists, usage might be for more complex ETL not detailed here).
*   **VPC Network:** Custom network configuration for resources.

### Application (API)
The API is built using FastAPI and follows Clean Architecture principles:
*   **`api/core`**: Contains Pydantic models for data structures.
*   **`api/repositories`**: Abstracts data access, specifically for loading the ML model.
*   **`api/services`**: Implements the business logic (e.g., prediction service).
*   **`api/main.py`**: Defines FastAPI routes and dependency injection.

The API provides an endpoint for predicting Iris flower species based on input features.

### ETL
An Apache Airflow DAG, managed by Google Cloud Composer, orchestrates a simple ETL process:
*   Loads data into a BigQuery table using a SQL script (`etl/sql/etl_covid.sql` - note: the name suggests COVID data, while the API is Iris; this might be a point of inconsistency to mention or assume it's illustrative).

## Prerequisites

*   **Google Cloud SDK (gcloud CLI):** Installed and configured. [Installation Guide](https://cloud.google.com/sdk/docs/install)
*   **Terraform:** Version 1.x.x or later. [Installation Guide](https://learn.hashicorp.com/tutorials/terraform/install-cli)
*   **Docker:** To build and publish the API image. [Installation Guide](https://docs.docker.com/engine/install/)
*   **Git:** For cloning the repository.
*   **Google Cloud Project:** A GCP project with billing enabled.
*   **Permissions:** Your GCP user/SA should have necessary roles (e.g., Project Owner, or a combination of roles like Cloud Run Admin, Storage Admin, BigQuery Admin, Service Account User, etc.) to create and manage resources.
*   **Enable APIs:** The necessary GCP APIs (Compute Engine, Cloud Run, BigQuery, Artifact Registry, Cloud Composer, etc.) must be enabled in your project. The deployment scripts attempt to do this, but it's good to be aware.

## Setup

1.  **Clone the repository:**
    ```bash
    git clone <repository_url>
    cd <repository_name>
    ```

2.  **Authenticate with GCP (for local deployment):**
    Ensure you are authenticated to the correct project.
    ```bash
    gcloud auth application-default login
    gcloud config set project YOUR_PROJECT_ID
    ```

3.  **Configure Terraform Backend:**
    The Terraform state is stored in a GCS bucket.
    *   Open the `terraform/backend.tf` file.
    *   Replace `your-gcp-terraform-state-bucket-name` with the name of a GCS bucket you have created or will create for storing Terraform state. This bucket must exist before you can initialize Terraform.
    *   Example:
        ```bash
        gsutil mb gs://my-unique-terraform-state-bucket
        ```
        Then update `terraform/backend.tf`:
        ```terraform
        terraform {
          backend "gcs" {
            bucket = "my-unique-terraform-state-bucket" # UPDATE THIS
            prefix = "terraform/state"
          }
        }
        ```

4.  **Configure Terraform Variables:**
    *   Navigate to the `terraform` directory:
        ```bash
        cd terraform
        ```
    *   Copy the example variables file:
        ```bash
        cp terraform.tfvars.example terraform.tfvars
        ```
    *   Edit `terraform/terraform.tfvars` and provide values for your specific setup:
        *   `project_id`: Your GCP Project ID.
        *   `region`: The GCP region for deployment (e.g., "us-central1").
        *   `location`: The GCP location for global resources (e.g., "US").
        *   `service_account_email`: The email of the GCP service account Terraform will use (this SA should have necessary permissions). If you plan to use the GitHub Actions, this often refers to the SA the actions impersonate.
        *   `container_image`: The full path for your API image in Artifact Registry (e.g., `us-central1-docker.pkg.dev/YOUR_PROJECT_ID/docker-repo/iris-api:latest`). Ensure `YOUR_PROJECT_ID` is replaced.
        *   `dataset_id`: Name for the BigQuery dataset.
        *   `cloud_run_service_name`: Name for the Cloud Run service.
        *   `repository_name`: Name of the Artifact Registry repository (e.g., "docker-repo").
    *   Return to the root directory:
        ```bash
        cd ..
        ```

## Deployment

There are two ways to deploy:

### 1. Local Deployment (using `deploy.sh` script)

The `deploy.sh` script automates the Docker build/push and Terraform deployment process.
Make sure you have completed the [Setup](#setup) steps first.

```bash
# Ensure deploy.sh is executable
chmod +x deploy.sh

# Run the deployment script
./deploy.sh
```
This script will:
1.  Authenticate gcloud (if not already).
2.  Enable necessary GCP services.
3.  Build the Docker image for the API from the `api/` directory.
4.  Push the Docker image to Google Artifact Registry (configured via `terraform.tfvars`).
5.  Initialize and apply Terraform configurations from the `terraform/` directory.

### 2. Manual Terraform Deployment (from `terraform/` directory)

If you prefer to run Terraform commands manually:

```bash
# Navigate to the Terraform directory
cd terraform

# Initialize Terraform (only needed once or after backend/module changes)
terraform init

# (Optional) Create a plan
terraform plan -out=tfplan

# Apply the configuration
terraform apply # or terraform apply tfplan
```
Ensure your `terraform/terraform.tfvars` is correctly populated.

### 3. CI/CD with GitHub Actions

The project is configured with GitHub Actions for automated deployment on pushes to the `main` branch.
*   **Workflow:** `.github/workflows/deploy.yml`
*   **Authentication:** Uses Workload Identity Federation to authenticate with GCP.
*   **Secrets:** You need to configure the following secrets in your GitHub repository settings (`Settings > Secrets and variables > Actions`):
    *   `GCP_PROJECT_ID`: Your Google Cloud Project ID (e.g., `my-gcp-project-123`).
    *   `GCP_WORKLOAD_IDENTITY_PROVIDER`: The full resource name of your Workload Identity Pool Provider. This is used by GitHub Actions to securely authenticate with Google Cloud.
        *   Format: `projects/YOUR_PROJECT_NUMBER/locations/global/workloadIdentityPools/YOUR_POOL_ID/providers/YOUR_PROVIDER_ID`
        *   Example: `projects/123456789012/locations/global/workloadIdentityPools/github-actions-pool/providers/github-actions-provider`
    *   `GCP_SERVICE_ACCOUNT_EMAIL`: The email of the GCP service account that GitHub Actions will impersonate. This service account must have the necessary permissions to manage resources defined in the Terraform configuration.
        *   Example: `terraform-runner@my-gcp-project-123.iam.gserviceaccount.com`
*   The workflow will build and push the Docker image and then run `terraform apply`.

## API Usage

Once deployed, the API will be accessible via a Cloud Run URL. The URL will be output by the `deploy.sh` script or the GitHub Actions workflow.

*   **Endpoint:** `/predict`
*   **Method:** `POST`
*   **Request Body (JSON):**
    ```json
    {
      "sepal_length": 5.1,
      "sepal_width": 3.5,
      "petal_length": 1.4,
      "petal_width": 0.2
    }
    ```
*   **Example with curl:**
    ```bash
    CLOUD_RUN_URL="YOUR_CLOUD_RUN_SERVICE_URL" # Get this from deployment output
    curl -X POST "${CLOUD_RUN_URL}/predict" \
        -H "Content-Type: application/json" \
        -d '{
          "sepal_length": 5.1,
          "sepal_width": 3.5,
          "petal_length": 1.4,
          "petal_width": 0.2
        }'
    ```
*   **Success Response (JSON):**
    ```json
    {
      "class_id": 0,
      "class_name": "Setosa"
    }
    ```

*   **Health Check Endpoint:** `/health` (GET) - returns `{"status": "healthy"}`

## ETL Information

*   **Cloud Composer:** Manages Airflow DAGs.
*   **DAG File:** `etl/dags/etl_dags.py`
*   **SQL Script:** `etl/sql/etl_covid.sql`
*   The primary DAG `covid_etl` (as named in `etl_dags.py`) runs a BigQuery job. You can monitor and manage this DAG through the Airflow UI provided by your Cloud Composer environment.
*   *(Note: The ETL DAG (`covid_etl`) and SQL script (`etl_covid.sql`) seem to be placeholders or examples using COVID data, which is different from the Iris API's domain. This might be for illustrative purposes.)*

## Destroying Infrastructure

There are two ways to destroy the deployed resources:

### 1. Using `destroy.sh` script

```bash
# Ensure destroy.sh is executable
chmod +x destroy.sh

# Run the destruction script
./destroy.sh
```
This script will run `terraform destroy` from the `terraform/` directory and attempt to remove the Docker image from Artifact Registry.

### 2. Manual Terraform Destruction (from `terraform/` directory)

```bash
cd terraform
terraform destroy -auto-approve
```

### 3. CI/CD with GitHub Actions

The `.github/workflows/destroy.yml` workflow can be used to destroy the infrastructure, typically triggered manually via `workflow_dispatch`. It requires the same GitHub secrets as the deployment workflow.

## Development

*   **API Code:** Located in the `api/` directory.
*   **Terraform Code:** Located in the `terraform/` directory. This includes modules, variables, and main configuration files.
*   **ETL DAGs:** Located in `etl/dags/`.
*   **Deployment Scripts:** `deploy.sh` and `destroy.sh` are in the root directory.
*   **GitHub Actions Workflows:** Located in `.github/workflows/`.

### Model Training
The script to train the Iris classification model is `api/model/train_iris_model.py`. If you retrain the model, the `api/model/iris_classifier.joblib` file will be updated. You would then need to rebuild and redeploy the API to use the new model. This typically involves:
1. Running `python api/model/train_iris_model.py`.
2. Re-running the deployment process (e.g., `./deploy.sh` or pushing to `main` for GitHub Actions) to build a new Docker image with the updated model and redeploy it.