#!/bin/bash

# Change this to fit your own unique names
GCS_BUCKET_NAME="dezoomcamp_2025_analytics_engineering_hw4"
BQ_DATASET_NAME="nyc_taxi_data_hw4"

DATA_BASE_URL="https://github.com/DataTalksClub/nyc-tlc-data/releases/download"
GCS_BUCKET_URL="gs://$GCS_BUCKET_NAME"

# Check if the bucket exists; if not, create it
if ! gsutil ls -b "$GCS_BUCKET_URL/" &>/dev/null; then
    echo "Bucket $GCS_BUCKET_NAME does not exist. Creating it now..."
    gsutil mb -l US "$GCS_BUCKET_URL/" &>/dev/null
    echo "Bucket $GCS_BUCKET_NAME created successfully."
else
    echo "Using existing bucket: $GCS_BUCKET_NAME"
fi

# Check if the BigQuery dataset exists
if ! bq show --format=none "$BQ_DATASET_NAME" &>/dev/null; then
    echo "Dataset $BQ_DATASET_NAME does not exist. Creating it now..."
    bq mk "$BQ_DATASET_NAME" &>/dev/null
    echo "Dataset $BQ_DATASET_NAME created successfully."
else
    echo "Using existing dataset: $BQ_DATASET_NAME"
fi

# Function to upload the data to GCS
upload_nyc_taxi_data() {
  local color="$1"
  shift
  local years=("$@")

  # Upload to GCS
  for year in "${years[@]}"; do
    for month in {01..12}; do
      filepath="${color}/${color}_tripdata_${year}-${month}.csv.gz"
      echo "Uploading: $DATA_BASE_URL/${filepath}"
      curl -sSL "$DATA_BASE_URL/${filepath}" | gsutil cp - "$GCS_BUCKET_URL/${filepath}"
    done
  done

  # Load into BigQuery
  bq load --source_format=CSV --replace --autodetect --skip_leading_rows=1 \
    "$BQ_DATASET_NAME.nyc_taxi_${color}" "$GCS_BUCKET_URL/${color}/${color}_tripdata_*.csv.gz"
}

# Upload the data required for the homework
upload_nyc_taxi_data "green" 2019 2020
upload_nyc_taxi_data "yellow" 2019 2020
upload_nyc_taxi_data "fhv" 2019

echo "Upload process completed."