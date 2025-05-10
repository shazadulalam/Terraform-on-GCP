# modules/composer/main.tf
resource "google_composer_environment" "etl_orchestration" {
  name   = "etl-composer-env"
  region = var.region
  config {
    workloads_config {
      scheduler {
        cpu        = 0.5
        memory_gb  = 1.875
        storage_gb = 1
        count      = 1
      }
      web_server {
        cpu        = 0.5
        memory_gb  = 1.875
        storage_gb = 1
      }
      worker {
        cpu        = 0.5
        memory_gb  = 1.875
        storage_gb = 1
        min_count  = 1
        max_count  = 3
      }
    }
    environment_size = "ENVIRONMENT_SIZE_SMALL"
    software_config {
      image_version = "composer-2-airflow-2"
    }
  }
}