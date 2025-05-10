variable "project_id" {
  type = string
}

variable "location" {
  type = string
}

variable "buckets" {
  description = "Application buckets (not including state bucket)"
  type        = list(string)
  default     = ["raw-data", "processed-data"]  # Example app buckets
}