# Module 1 Homework: Docker + SQL

- [Summary](#summary)
- [Running the Docker commands](#running-the-docker-commands)
- [Homework answers](#homework-answers)

## Summary

The objective of this module was familiarizing with the Docker and Terraform CLI commands and a quick refresher on SQL and Python syntax.

For that, I built a data ingestion pipeline as a Python script for the NYC taxi dataset, which would upload the data into a PostgreSQL database for then to be queried with the pgAdmin interface. All integrated as Docker containers and orchestrated with Docker Compose.

Also, at the end I had to create a GCP account and manage some resources with Terraform to get familiar with it.

## Running the Docker commands

To deploy the Docker containers:

```bash
# Clone the repo
git clone https://github.com/goosethedev/de-zoomcamp-2025.git
cd de-zoomcamp-2025/01-docker-terraform

# Download the data to ingest
wget -P ./data https://github.com/DataTalksClub/nyc-tlc-data/releases/download/green/green_tripdata_2019-10.csv.gz
wget -P ./data https://github.com/DataTalksClub/nyc-tlc-data/releases/download/misc/taxi_zone_lookup.csv

# Setup the .env file from the example file
# Make changes if you like
cp .env.example .env

# Deploy the containers
docker compose up -d
```

Then, you can access to `http://localhost:8080` with your browser to access the *pgAdmin* interface. Use the credentials from the `.env` file, which by default are:

- Email: `pgadmin@example.com`
- Password: `pgadmin`

Then setup a server with the container specs from the `.env` file. The defaults are:

- Host: `postgres-db`
- Port: `5432`
- DB name: `ny_taxi`
- DB user: `admin`
- DB password: `admin`

Once connected, you can run queries against the ingested data.

## Homework answers

### Q1. Understanding docker first run

Run docker with the `python:3.12.8` image in an interactive mode, use the entrypoint `bash`.

What's the version of pip in the image?

- **`24.3.1` << CORRECT**
- `24.2.1`
- `23.3.1`
- `23.2.1`

```bash
docker run -it python:3.12.8 bash
pip --version
# pip 24.3.1 from /usr/local/lib/python3.12/site-packages/pip (python 3.12)
```

### Q2. Understanding Docker networking and docker-compose

Given the following docker-compose.yaml, what is the hostname and port that pgadmin should use to connect to the postgres database?

<details>

  <summary>Docker compose YAML file</summary>

  ```yaml
  services:
    db:
      container_name: postgres
      image: postgres:17-alpine
      environment:
        POSTGRES_USER: 'postgres'
        POSTGRES_PASSWORD: 'postgres'
        POSTGRES_DB: 'ny_taxi'
      ports:
        - '5433:5432'
      volumes:
        - vol-pgdata:/var/lib/postgresql/data

    pgadmin:
      container_name: pgadmin
      image: dpage/pgadmin4:latest
      environment:
        PGADMIN_DEFAULT_EMAIL: "pgadmin@pgadmin.com"
        PGADMIN_DEFAULT_PASSWORD: "pgadmin"
      ports:
        - "8080:80"
      volumes:
        - vol-pgadmin_data:/var/lib/pgadmin  

  volumes:
    vol-pgdata:
      name: vol-pgdata
    vol-pgadmin_data:
      name: vol-pgadmin_data
  ```

</details>

- postgres:5433
- localhost:5432
- db:5433
- **postgres:5432 << CORRECT**
- db:5432

Since the *pgAdmin* web server is run within a Docker container, it must communicate with the PostgreSQL instance (implicitly within the same virtual network) using its container name (not the service name) and internal port (not the one forwarded to the host).

### Q3. Trip segmentation count

During the period of October 1st 2019 (inclusive) and November 1st 2019 (exclusive), how many trips, respectively, happened:

- Up to 1 mile
- In between 1 (exclusive) and 3 miles (inclusive),
- In between 3 (exclusive) and 7 miles (inclusive),
- In between 7 (exclusive) and 10 miles (inclusive),
- Over 10 miles

Answers:

- 104,802; 197,670; 110,612; 27,831; 35,281
- **104,802; 198,924; 109,603; 27,678; 35,189 << CORRECT**
- 104,793; 201,407; 110,612; 27,831; 35,281
- 104,793; 202,661; 109,603; 27,678; 35,189
- 104,838; 199,013; 109,645; 27,688; 35,202

```postgresql
SELECT * FROM (
  SELECT
    CASE
      WHEN trip_distance <= 1 THEN '<1 mile'
      WHEN trip_distance > 1
      AND trip_distance <= 3 THEN '1-3 miles'
      WHEN trip_distance > 3
      AND trip_distance <= 7 THEN '3-7 miles'
      WHEN trip_distance > 7
      AND trip_distance <= 10 THEN '7-10 miles'
      ELSE '>10 miles'
    END AS trip_group,
    COUNT(*) as trip_amount
  FROM
    trips
  WHERE
    1 = 1
    AND lpep_pickup_datetime >= '2019-10-01'
    AND lpep_dropoff_datetime < '2019-11-01'
  GROUP BY
    trip_group)
ORDER BY
  CASE
    WHEN trip_group = '<1 mile' THEN 1
    WHEN trip_group = '1-3 miles' THEN 2
    WHEN trip_group = '3-7 miles' THEN 3
    WHEN trip_group = '7-10 miles' THEN 4
    ELSE 5
  END;
```

| trip_group | trip_amount |
|------------|-------------|
| <1 mile    | 104802      |
| 1-3 miles  | 198924      |
| 3-7 miles  | 109603      |
| 7-10 miles | 27678       |
| >10 miles  | 35189       |

*Note:* Outer query used only for ordering the output table. It could be omitted for the same results ordered alphabetically.

### Q4. Longest trip for each day

Which was the pick up day with the longest trip distance? Use the pick up time for your calculations.

Tip: For every day, we only care about one single trip with the longest distance.

- 2019-10-11
- 2019-10-24
- 2019-10-26
- **2019-10-31 << CORRECT**

```postgresql
SELECT
  DATE(lpep_pickup_datetime) as trip_date,
  MAX(trip_distance) as longest_trip_distance
FROM trips
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1;
```

| trip_date  | longest_trip_distance |
|------------|-----------------------|
| 2019-10-31 | 515.89                |

### Q5. Three biggest pickup zones

Which were the top pickup locations with over 13,000 in total_amount (across all trips) for 2019-10-18?

Consider only lpep_pickup_datetime when filtering by date.

- **East Harlem North, East Harlem South, Morningside Heights << CORRECT**
- East Harlem North, Morningside Heights
- Morningside Heights, Astoria Park, East Harlem South
- Bedford, East Harlem North, Astoria Park

```postgresql
SELECT z."Zone" AS pickup_location, COUNT(z."Zone") AS pickup_count
FROM trips t
JOIN zones z on t."PULocationID" = z."LocationID"
WHERE 1=1
AND DATE(t.lpep_pickup_datetime) = '2019-10-18'
GROUP BY 1
HAVING SUM(t.total_amount) > 13000
ORDER BY 2 DESC
LIMIT 3;
```

| pickup_location     | pickup_count |
|---------------------|--------------|
| East Harlem North   | 1236         |
| East Harlem South   | 1101         |
| Morningside Heights | 764          |

### Q6. Largest tip

For the passengers picked up in Ocrober 2019 in the zone name "East Harlem North" which was the drop off zone that had the largest tip?

Note: it's tip , not trip

We need the name of the zone, not the ID.

- Yorkville West
- **JFK Airport << CORRECT**
- East Harlem North
- East Harlem South

```postgresql
SELECT
  zd."Zone" AS dropoff_location,
  MAX(t.tip_amount) as max_tip
FROM trips t
  JOIN zones zp ON t."PULocationID" = zp."LocationID"
  JOIN zones zd ON t."DOLocationID" = zd."LocationID"
WHERE 1=1
  AND t.lpep_pickup_datetime >= '2019-10-01'
  AND t.lpep_pickup_datetime < '2019-11-01'
  AND zp."Zone" = 'East Harlem North'
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1;
```

| dropoff_location | max_tip |
|------------------|---------|
| JFK Airport      | 87.3    |

### Q7. Terraform Workplow

Which of the following sequences, respectively, describes the workflow for:

1. Downloading the provider plugins and setting up backend,
2. Generating proposed changes and auto-executing the plan
3. Remove all resources managed by terraform`

Answers:

- terraform import, terraform apply -y, terraform destroy
- terraform init, terraform plan -auto-apply, terraform rm
- terraform init, terraform run -auto-approve, terraform destroy
- **terraform init, terraform apply -auto-approve, terraform destroy << CORRECT**
- terraform import, terraform apply -y, terraform rm

Using the help from the command line:

```bash
terraform init --help

# Initialize a new or existing Terraform working directory by creating initial files, loading any remote state, downloading modules, etc.

# This is the first command that should be run for any new or existing Terraform configuration per machine. This sets up all the local data necessary to run Terraform that is typically not committed to version control.

terraform apply --help

# Creates or updates infrastructure according to Terraform configuration files in the current directory.

# By default, Terraform will generate a new plan and present it for your approval before taking any action. You can optionally provide a plan file created by a previous call to "terraform plan", in which case Terraform will take the actions described in that plan without any confirmation prompt.

# -auto-approve          Skip interactive approval of plan before applying.

terraform destroy --help

# Destroy Terraform-managed infrastructure.

# This command also accepts many of the plan-customization options accepted by the terraform plan command. For more information on those options, run: terraform plan -help
```
