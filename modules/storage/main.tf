resource "google_storage_bucket" "app_buckets" {
  for_each = toset(var.buckets)
  name     = "${var.project_id}-${each.key}"  # Unique bucket names
  location = var.location
  project  = var.project_id
}