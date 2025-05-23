resource "google_project_service" "required_apis" {
  for_each = toset([
    "run.googleapis.com",
    "composer.googleapis.com",
    "dataflow.googleapis.com",
    "bigquery.googleapis.com",
    "compute.googleapis.com"
  ])

  service            = each.key
  disable_on_destroy = false
}