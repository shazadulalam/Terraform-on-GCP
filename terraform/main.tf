provider "google" {
  project = var.project_id
  region  = var.region
}

module "storage" {
  source     = "./modules/storage"
  project_id = var.project_id
  location   = var.location
  buckets    = var.buckets
}

module "bigquery" {
  source     = "./modules/bigquery"
  project_id = var.project_id
  dataset_id = var.dataset_id
  location   = var.location
  tables     = var.tables
}

module "dataflow" {
  source          = "./modules/dataflow"
  project_id      = var.project_id
  region          = var.region
  temp_location   = "${module.storage.bucket_name}/temp"  # Changed from data_bucket
  service_account = var.service_account_email
  dataset_id      = module.bigquery.dataset_id
}

module "networking" {
  source   = "./modules/networking"
  region   = var.region
}

module "composer" {
  source          = "./modules/composer"
  project_id      = var.project_id
  region          = var.region
  network         = module.networking.network_name
  subnetwork      = module.networking.subnetwork_name
  service_account = var.service_account_email
  depends_on = [module.apis]
}

module "cloudrun" {
  source          = "./modules/cloudrun"
  project_id      = var.project_id
  region          = var.region
  service_account = var.service_account_email
  container_image = var.container_image
  depends_on = [module.apis]
}

module "monitoring" {
  source     = "./modules/monitoring"
  project_id = var.project_id
  region     = var.region
}

module "apis" {
  source = "./modules/apis"
}