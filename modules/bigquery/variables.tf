variable "project_id" {
  type = string
}

variable "dataset_id" {
  type = string
  default = "covid_data"
}

variable "location" {
  type    = string
  default = "US"
}

variable "tables" {
  type = list(object({
    table_id = string
    schema   = string
  }))
}