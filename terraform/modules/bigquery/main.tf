resource "google_bigquery_dataset" "dataset" {
  dataset_id = var.dataset_id
  project    = var.project_id
  location   = var.location
}

resource "google_bigquery_table" "default_table" {
  dataset_id = google_bigquery_dataset.dataset.dataset_id
  table_id   = "daily_covid_summary"
  deletion_protection = false

  schema = <<EOF
[
  {"name": "country_region", "type": "STRING"},
  {"name": "date", "type": "DATE"},
  {"name": "total_confirmed", "type": "INT64"},
  {"name": "total_deaths", "type": "INT64"},
  {"name": "total_recovered", "type": "INT64"}
]
EOF
}