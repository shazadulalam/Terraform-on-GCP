resource "google_dataflow_job" "etl_job" {
  name              = "covid-etl-job"
  template_gcs_path = "gs://dataflow-templates/latest/PubSub_to_BigQuery"
  parameters = {
    inputTopic    = "projects/${var.project_id}/topics/covid-input"
    outputTableSpec = "${var.project_id}:${var.dataset_id}.daily_covid_summary"
  }
  temp_gcs_location = var.temp_location
  service_account_email = var.service_account
  project               = var.project_id
  region                = var.region
}