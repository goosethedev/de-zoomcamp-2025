# Kestra credentials
variable "kestra_username" {
  description = "Kestra username"
  type        = string
  sensitive   = true
}

variable "kestra_password" {
  description = "Kestra password"
  type        = string
  sensitive   = true
}

# GCP values
variable "gcp_creds_file" {
  description = "The GCP exported credentials"
  type        = string
  default     = "./gcp_creds.json"
  sensitive   = true
}

variable "gcp_project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "gcp_location" {
  description = "The GCP region location"
  type        = string
  default     = "us-east-1"
}

variable "gcp_bucket_name" {
  description = "Name of the GCS bucket"
  type        = string
}

variable "gcp_bq_dataset_name" {
  description = "Name of the BigQuery dataset"
  type        = string
}
