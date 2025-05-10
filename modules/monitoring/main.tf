resource "google_monitoring_alert_policy" "dataflow_alerts" {
  display_name = "Dataflow Job Alerts"
  combiner     = "OR"

  conditions {
    display_name = "Dataflow Job Using vCPUs"
    condition_threshold {
      filter     = "resource.type=\"dataflow_job\" AND metric.type=\"dataflow.googleapis.com/job/current_num_vcpus\""
      duration   = "600s"
      comparison = "COMPARISON_GT"
      threshold_value = 0

      aggregations {
        alignment_period   = "600s"
        per_series_aligner = "ALIGN_MAX"
      }
    }
  }
}

resource "google_monitoring_alert_policy" "bigquery_alerts" {
  display_name = "BigQuery Failed Jobs Alert"
  combiner     = "OR"

  conditions {
    display_name = "High BigQuery Job Failure Rate"
    condition_threshold {
      filter = "resource.type=\"bigquery_project\" AND metric.type=\"logging.googleapis.com/user/bigquery_failed_jobs\""
      duration   = "300s"
      comparison = "COMPARISON_GT"
      threshold_value = 5

      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }
}
