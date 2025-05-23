variable "project_id" {
  type        = string
  description = "The GCP project ID where resources will be deployed. Example: 'my-gcp-project'."
}

variable "region" {
  type        = string
  description = "The GCP region for deploying resources, e.g., 'us-central1'."
  default     = "us-central1"
}

variable "location" {
  type        = string
  description = "The GCP location for resources like Cloud Storage buckets or BigQuery datasets, e.g., 'US', 'EU', 'us-central1'."
  default     = "US"
}

variable "service_account_email" {
  type        = string
  description = "The email address of the GCP service account to be used for deploying and managing resources. Example: 'my-service-account@my-gcp-project.iam.gserviceaccount.com'."
}

variable "container_image" {
  type        = string
  description = "The full URI of the container image to be deployed to Cloud Run. Example: 'us-central1-docker.pkg.dev/my-gcp-project/my-repo/my-image:latest'."
}

variable "dataset_id" {
  type        = string
  description = "The ID of the BigQuery dataset to be created or used. Example: 'my_bq_dataset'."
  default     = "iris_dataset"
}

variable "cloud_run_service_name" {
  type        = string
  description = "The name for the Cloud Run service."
  default     = "iris-api-service"
}

variable "repository_name" {
  type        = string
  description = "The name of the Artifact Registry Docker repository."
  default     = "docker-repo"
}
