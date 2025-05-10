terraform {
  backend "gcs" {
    bucket  = "gcp-state-terraform"  # Your existing bucket
    prefix  = "terraform/state"      # State file path
  }
}