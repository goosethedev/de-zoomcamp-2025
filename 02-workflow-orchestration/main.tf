terraform {
  required_providers {
    kestra = {
      source  = "kestra-io/kestra"
      version = "0.20.1"
    }
  }
}

provider "kestra" {
  url      = "http://localhost:8080"
  username = var.kestra_username
  password = var.kestra_password
}

# Import local flows
resource "kestra_flow" "local_flows" {
  for_each  = fileset(path.module, "kestra-flows/*.yaml")
  flow_id   = yamldecode(templatefile(each.value, {}))["id"]
  namespace = yamldecode(templatefile(each.value, {}))["namespace"]
  content   = templatefile(each.value, {})
}

# This one should be a secret, but the open-source Kestra HTTP API
# does not support uploading them, only KV pairs
resource "kestra_kv" "gcp_creds" {
  namespace = "zoomcamp"
  key       = "GCP_CREDS"
  value     = file(var.gcp_creds_file)
  type      = "JSON"
}

# Import key-value pairs
resource "kestra_kv" "gcp_project_id" {
  namespace = "zoomcamp"
  key       = "GCP_PROJECT_ID"
  value     = var.gcp_project_id
  type      = "STRING"
}

resource "kestra_kv" "gcp_location" {
  namespace = "zoomcamp"
  key       = "GCP_LOCATION"
  value     = var.gcp_location
  type      = "STRING"
}

resource "kestra_kv" "gcp_bucket_name" {
  namespace = "zoomcamp"
  key       = "GCP_BUCKET_NAME"
  value     = var.gcp_bucket_name
  type      = "STRING"
}

resource "kestra_kv" "gcp_bq_dataset_name" {
  namespace = "zoomcamp"
  key       = "GCP_BQ_DATASET_NAME"
  value     = var.gcp_bq_dataset_name
  type      = "STRING"
}
