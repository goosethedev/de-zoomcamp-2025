# Module 3 Homework: Data Warehousing

- [Summary](#summary)
- [Prerequisites](#prerequisites)
- [Homework answers](#homework-answers)

## Summary

The objective of this module was getting familiar with Google's BigQuery as a managed data warehousing solution.

For that, it was necessary to upload the data from the [NYC Yellow Taxi records](https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page) for January-July 2024 in Parquet format to a GCS bucket, to then create **two tables** in BigQuery: one **regular** and another **external**.

With that, it was possible to query the data with the SQL-like syntax from the BigQuery Studio platform.

**Bonus!** A Python script was provided to upload the Yellow Taxi data, first downloading it locally and then uploading it to GCS, but I decided to write [a Bash script](load-yellow-taxi-data.sh) that could run natively on the Google's Cloud Shell to avoid local downloads. Also, even if run locally, it wouldn't write anything on disk.

## Prerequisites

Go to [Google Cloud Console](https://console.cloud.google.com) and click on the top right shell icon (or press G + S).

Click on *Open Editor* and create an new file named `upload-taxi-data.sh`. In that file, copy and paste [the bash script](./load-yellow-taxi-data.sh) to upload the data.

**IMPORTANT**: Ensure to modify the name of the bucket to be unique.

Open a shell within the editor, to add execution permissions and run it the script:

```bash
chmod +x upload-taxi-data.sh
bash upload-taxi.data.sh
```

Check that the GCS bucket has been created and it contains the 6 Parquet files. Then proceed to BigQuery Studio to create the two tables using these files.

## Homework answers

### Q1. What is count of records for the 2024 Yellow Taxi Data?

- 65,623
- 840,402
- **20,332,093 << CORRECT**
- 85,431,289

```sql
SELECT COUNT(*) FROM `dataengineering-zoomcamp-2025.yellow_taxi_data_2024.yellow_taxi_data_external`;
```

### Q2. Write a query to count the distinct number of `PULocationID`s for the entire dataset on both the tables. What is the **estimated** amount of data that will be read when this query is executed on the External Table and the Materialized Table?

- 18.82 MB for the External Table and 47.60 MB for the Materialized Table
- **0 MB for the External Table and 155.12 MB for the Materialized Table << CORRECT**
- 2.14 GB for the External Table and 0 MB for the Materialized Table
- 0 MB for the External Table and 0 MB for the Materialized Table

```sql
-- Don't execute. Only check their estimations on the top-right corner.
SELECT COUNT(DISTINCT PULocationID) FROM `dataengineering-zoomcamp-2025.yellow_taxi_data_2024.yellow_taxi_data_external`;
-- This query will process 0 B when run.

SELECT COUNT(DISTINCT PULocationID) FROM `dataengineering-zoomcamp-2025.yellow_taxi_data_2024.yellow_taxi_data_regular`;
-- This query will process 155.12 MB when run.
```

### Q3. Write a query to retrieve the `PULocationID` from the table (not the external table) in BigQuery. Now write a query to retrieve the `PULocationID` and `DOLocationID` on the same table. Why are the estimated number of Bytes different?

- **BigQuery is a columnar database, and it only scans the specific columns requested in the query. Querying two columns (PULocationID, DOLocationID) requires reading more data than querying one column (PULocationID), leading to a higher estimated number of bytes processed. << CORRECT**
- BigQuery duplicates data across multiple storage partitions, so selecting two columns instead of one requires scanning the table twice, doubling the estimated bytes processed.
- BigQuery automatically caches the first queried column, so adding a second column increases processing time but does not affect the estimated bytes scanned.
- When selecting multiple columns, BigQuery performs an implicit join operation between them, increasing the estimated bytes processed

```sql
SELECT PULocationID FROM `dataengineering-zoomcamp-2025.yellow_taxi_data_2024.yellow_taxi_data_regular`;
-- This query will process 155.12 MB when run.

SELECT PULocationID, DOLocationID FROM `dataengineering-zoomcamp-2025.yellow_taxi_data_2024.yellow_taxi_data_regular`;
-- This query will process 310.24 MB when run.
```

### Q4. How many records have a `fare_amount` of 0?

- 128,210
- 546,578
- 20,188,016
- **8,333 << CORRECT**

```sql
SELECT COUNT(*) FROM `dataengineering-zoomcamp-2025.yellow_taxi_data_2024.yellow_taxi_data_regular`
WHERE fare_amount = 0;
```

### Q5. What is the best strategy to make an optimized table in Big Query if your query will always filter based on tpep_dropoff_datetime and order the results by VendorID (Create a new table with this strategy)

- **Partition by tpep_dropoff_datetime and Cluster on VendorID << CORRECT**
- Cluster on by tpep_dropoff_datetime and Cluster on VendorID
- Cluster on tpep_dropoff_datetime Partition by VendorID
- Partition by tpep_dropoff_datetime and Partition by VendorID

```sql
CREATE OR REPLACE TABLE `dataengineering-zoomcamp-2025.yellow_taxi_data_2024.yellow_taxi_data_partitioned_clustered`
PARTITION BY DATE(tpep_dropoff_datetime)
CLUSTER BY VendorID
AS SELECT * FROM `dataengineering-zoomcamp-2025.yellow_taxi_data_2024.yellow_taxi_data_regular`;
```

### Q6. Estimated processed bytes difference on regular vs. partitioned tables

Write a query to retrieve the distinct `VendorID`s between `tpep_dropoff_datetime` *2024-03-01* and *2024-03-15* (inclusive).

Use the materialized table you created earlier in your from clause and note the estimated bytes. Now change the table in the from clause to the partitioned table you created for question 5 and note the estimated bytes processed. What are these values?

Choose the answer which most closely matches.

- 12.47 MB for non-partitioned table and 326.42 MB for the partitioned table
- **310.24 MB for non-partitioned table and 26.84 MB for the partitioned table << CORRECT**
- 5.87 MB for non-partitioned table and 0 MB for the partitioned table
- 310.31 MB for non-partitioned table and 285.64 MB for the partitioned table

```sql
SELECT DISTINCT VendorID FROM `dataengineering-zoomcamp-2025.yellow_taxi_data_2024.yellow_taxi_data_regular`
WHERE tpep_dropoff_datetime BETWEEN '2024-03-01' AND '2024-03-15';
-- This query will process 310.24 MB when run.

SELECT DISTINCT VendorID FROM `dataengineering-zoomcamp-2025.yellow_taxi_data_2024.yellow_taxi_data_partitioned_clustered`
WHERE tpep_dropoff_datetime BETWEEN '2024-03-01' AND '2024-03-15';
-- This query will process 26.84 MB when run.
```

### Q7. Where is the data stored in the External Table you created?

- Big Query
- Container Registry
- **GCP Bucket << CORRECT**
- Big Table

The data is stored on a GCS bucket and retrieved everytime BigQuery performs a query.

### Q8. It is best practice in Big Query to always cluster your data?

- True
- **False << CORRECT**

With data less than 1 GB of size, the overhead of metadata calculations lead to a worse performance.

### Q9. (BONUS) No Points: Write a `SELECT COUNT(*)` query using the materialized table you created. How many bytes does it estimate will be read? Why?

The estimate is 0 bytes, since there is no need to read the actual data. BigQuery will only read the metadata to return a result back.
