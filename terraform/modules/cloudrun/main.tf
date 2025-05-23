# modules/cloudrun/main.tf
resource "google_cloud_run_service" "api" {
  name     = "iris-classifier"
  location = var.region
  
  template {
    metadata {
      annotations = {
        "run.googleapis.com/startup-timeout" = "3000s"  # Increased timeout
      }
    }
    
    spec {
      containers {
        image = "us-central1-docker.pkg.dev/${var.project_id}/docker-repo/iris-api:latest"
        
        ports {
          container_port = 8080
        }

        liveness_probe {
          http_get {
            path = "/health"
          }
          initial_delay_seconds = 20
          timeout_seconds = 10
        }

        startup_probe {
          http_get {
            path = "/health"
          }
          initial_delay_seconds = 30
          timeout_seconds = 5
          period_seconds = 10
          failure_threshold = 3
        }
      }
    }
  }
  
  traffic {
    percent         = 100
    latest_revision = true
  }
}