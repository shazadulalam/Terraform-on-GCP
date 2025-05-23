terraform {
  backend "gcs" {
    bucket = "your-gcp-terraform-state-bucket-name" # TODO: User must create this GCS bucket and update the name here.
    prefix = "terraform/state"
  }
}
