# Module 2 Homework: Kestra + GCP

- [Summary](#summary)
- [Prerequisites](#prerequisites)
- [Setting up and running the workflows with the Kestra UI](#setting-up-and-running-the-workflows-with-the-kestra-ui)
- [Homework answers](#homework-answers)

## Summary

The objective of this module was getting to know [Kestra](https://kestra.io) and how it can manage and schedule workflows that manipulate GCP resources.

For that, it was necessary to build data workflows inside Kestra to consume the NYC taxi dataset, process it from CSV files and add the files into PostgreSQL or GCP resources like Cloud Storage and aggregate it into a Big Query dataset.

I tested that uploading the data to PostgreSQL worked correctly, but since the data was very large, I decided to use GCP.

**Bonus!** I configured Terraform to populate Kestra with the flows to be executed and key-value pairs with information necessary to connect with GCP.

## Prerequisites

```bash
# Ensure you have installed Docker and Terraform.
docker --version
terraform -version

# Clone the repo
git clone https://github.com/goosethedev/de-zoomcamp-2025.git
cd de-zoomcamp-2025/02-workflow-orchestration

```

Examine the `docker-compose.yaml` and `pgadmin-init/servers.json` files to check the environment variables are set as you desire.

Then, create `terraform.tfvars` with the required variables to be imported into Kestra. You can use `terraform.tfvars.example` as a template.

Last, create a _Service Account_ in GCP with permissions to manage Cloud Storage and Big Query and download a JSON key file into `gcp_creds.json`. It should look like the `gcp_creds.json.example` file.

## Setting up and running the workflows with the Kestra UI

```bash
# Deploy the containers
docker compose up -d

# Populate the Kestra container
terraform apply
```

From then, you can access `http://localhost:8080` in your browser to view the Kestra UI. It should have the workflows imported and the key-value pairs imported into the `zoomcamp` namespace.

Now you can execute the `gcp_taxi_scheduled` flow from the _Triggers_ section as backfills to ingest the resources into GCP.

NOTE: the yellow taxi dataset is massive and will take several minutes to complete a single month.

## Homework answers

### Q1. Within the execution for Yellow Taxi data for the year 2020 and month 12: what is the uncompressed file size (i.e. the output file yellow_tripdata_2020-12.csv of the extract task)?

- **128.3 MB << CORRECT**
- 134.5 MB
- 364.7 MB
- 692.6 MB

### Q2. What is the value of the variable file when the inputs taxi is set to green, year is set to 2020, and month is set to 04 during execution?

- `{{inputs.taxi}}_tripdata_{{inputs.year}}-{{inputs.month}}.csv`
- **`green_tripdata_2020-04.csv` << CORRECT**
- `green_tripdata_04_2020.csv`
- `green_tripdata_2020.csv`

### Q3. How many rows are there for the Yellow Taxi data for the year 2020?

- 13,537.299
- **24,648,499 << CORRECT**
- 18,324,219
- 29,430,127

### Q4. How many rows are there for the Green Taxi data for the year 2020?

- 5,327,301
- 936,199
- **1,734,051 << CORRECT**
- 1,342,034

### Q5. How many rows are there for the Yellow Taxi data for March 2021?

- 1,428,092
- 706,911
- **1,925,152 << CORRECT**
- 2,561,031

### Q6. How would you configure the timezone to New York in a Schedule trigger?

- Add a timezone property set to EST in the Schedule trigger configuration
- **Add a timezone property set to America/New_York in the Schedule trigger configuration << CORRECT**
- Add a timezone property set to UTC-5 in the Schedule trigger configuration
- Add a location property set to New_York in the Schedule trigger configuration

This one is described in the [Schedule Trigger documentation](https://kestra.io/docs/workflow-components/triggers/schedule-trigger#example-a-schedule-that-runs-every-quarter-of-an-hour).
