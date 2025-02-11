#!/bin/bash

# Change this to your own unique bucket name
BUCKET_NAME="dezoomcamp_2025_data_warehouse_hw3"

# Check if the bucket exists; if not, create it
if ! gsutil ls -b "gs://${BUCKET_NAME}/" &>/dev/null; then
    echo "Bucket ${BUCKET_NAME} does not exist. Creating..."
    gsutil mb -l US "gs://${BUCKET_NAME}/"
    echo "Bucket ${BUCKET_NAME} created successfully."
else
    echo "Bucket ${BUCKET_NAME} already exists."
fi

# Loop over months from January (01) to June (06)
for month in {01..06}; do
    FILE_NAME="yellow_tripdata_2024-${month}.parquet"
    FILE_PATH="gs://${BUCKET_NAME}/${FILE_NAME}"
    URL="https://d37ci6vzurychx.cloudfront.net/trip-data/${FILE_NAME}"

    # Check if the file already exists in GCS
    if gsutil -q stat "$FILE_PATH"; then
        echo "File ${FILE_NAME} already exists in GCS. Skipping..."
        continue
    fi

    echo "Streaming ${FILE_NAME} directly to GCS..."

    # Use curl to fetch the file and pipe it directly to gsutil
    if curl -s "$URL" | gsutil cp - "$FILE_PATH"; then
        echo "Successfully uploaded ${FILE_NAME} to ${FILE_PATH}"
    else
        echo "Failed to upload ${FILE_NAME}. Skipping..."
    fi
done

echo "Upload process completed."