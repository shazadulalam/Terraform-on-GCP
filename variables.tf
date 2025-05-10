variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
  default     = "us-central1"
}

variable "location" {
  description = "The dataset location"
  type        = string
  default     = "US"
}

variable "dataset_id" {
  description = "BigQuery dataset ID"
  type        = string
  default     = "etl_dataset"
}

variable "service_account_email" {
  description = "Service account email for resource access"
  type        = string
}

variable "buckets" {
  description = "List of GCS buckets to create"
  type        = list(string)
  default     = ["raw-data", "processed-data", "tf-state"]  # Remove generic names
}

variable "tables" {
  description = "BigQuery table configurations"
  type = list(object({
    table_id = string
    schema   = string
  }))
  default = [
    {
      table_id = "daily_covid_summary"
      schema   = "schemas/covid_summary.json"
    }
  ]
}

variable "container_image" {
  description = "Cloud Run container image URL"
  type        = string
  default     = "gcr.io/PROJECT_ID/iris-api:latest"
}

variable "backend_bucket" {
  description = "GCS bucket for Terraform state"
  type        = string
}

locals {
  computed_backend_bucket = var.backend_bucket != "" ? var.backend_bucket : "tf-state-${var.project_id}"
}