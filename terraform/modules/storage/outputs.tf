output "bucket_name" {
  value = google_storage_bucket.app_buckets["raw-data"].name
}