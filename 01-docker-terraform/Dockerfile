FROM python:3.12.8-alpine3.21

WORKDIR /app

# Copy the requirements.txt and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the data directory and the ingestion script
COPY data/ ./data/
COPY .env .
COPY ingest_data.py .

# Run the ingestion script for both files
# Add "--overwrite" for replacing the data in the next execution
CMD python ingest_data.py --file data/taxi_zone_lookup.csv --table zones && \
  python ingest_data.py --file data/green_tripdata_2019-10.csv.gz --table trips 
