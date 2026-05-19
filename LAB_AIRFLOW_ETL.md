# Airflow ETL Lab (MovieLens on HDFS + Hive)

A short, hands-on lab that adds Apache Airflow to the existing mini Hadoop cluster. You will orchestrate an ETL pipeline that lands data in HDFS, builds Hive warehouse tables, runs analytics, and sends an email notification.

Time box: 25 to 30 minutes.

## What you will build

- An Airflow ETL DAG that uses FileSensor, HiveServer2Operator, SqlSensor, and TriggerDagRunOperator.
- A downstream analytics DAG that uses ExternalTaskSensor and EmailOperator.
- A Hive warehouse backed by HDFS storage.
- A clear example of distributed storage and compute through HDFS and Hive.

## Prerequisites

- Docker and Docker Compose installed.
- This repository cloned and in your terminal.
- At least 8 GB RAM available for Docker.

## Lab steps

### 1. Start the Hadoop + Hive cluster

```bash
chmod +x ./scripts/*
./scripts/download_driver.sh
docker compose up -d
```

Wait for containers to become healthy:

```bash
docker ps
```

### 2. Download the dataset and load to HDFS

```bash
./scripts/download_dataset.sh
./scripts/load_data_to_hdfs.sh
```

This puts the MovieLens CSV files into HDFS where Hive reads them in later tasks.

### 3. Start Airflow on the same Docker network

This lab uses a separate compose file based on the standard Airflow docker-compose layout, attached to the existing `hive-network`.

```bash
docker compose -f docker-compose.yml -f docker-compose.airflow.yml up -d
```

Open Airflow UI: http://localhost:8080

Default login (created by the `airflow-init` container):

- Username: `airflow`
- Password: `airflow`

### 4. Configure the notification email

Update SMTP settings in `docker-compose.airflow.yml` to point to your SMTP provider (Mailtrap is fine for testing).

Then set a recipient email in Airflow:

1. Open Airflow UI.
2. Admin -> Variables -> Add.
3. Key: `alert_email`
4. Value: your email address.

Restart Airflow after editing the compose file:

```bash
docker compose -f docker-compose.yml -f docker-compose.airflow.yml up -d
```

### 5. Run the ETL DAG

In the Airflow UI, trigger the `movielens_etl` DAG.

Pipeline tasks:

- `wait_for_dataset`: FileSensor waits for `/datasets/ml-latest-small/movies.csv`.
- `create_staging`: Loads raw CSV tables in Hive.
- `etl_warehouse`: Builds ORC warehouse tables in Hive.
- `quality_check`: Confirms at least one row exists in `movielens.movies_orc`.
- `trigger_analytics`: Triggers the downstream DAG.

### 6. Observe the analytics DAG and email

The `movielens_analytics` DAG starts automatically.

- `wait_for_etl`: ExternalTaskSensor waits for the ETL warehouse task.
- `run_analytics`: Executes analytic queries in Hive.
- `notify`: Sends an email when the analytics step finishes (success or failure).

Check your email or Mailtrap inbox for the notification.

### 7. Validate outputs in Hive and HDFS

Use Hue or CLI to confirm tables and data:

```bash
docker exec hiveserver2 hive -e "SHOW TABLES IN movielens;"
docker exec hiveserver2 hdfs dfs -ls /user/hive/warehouse/movielens.db
```

## Where the distributed part shows up

- HDFS stores data in a distributed filesystem, and Hive reads those blocks in parallel.
- Hive queries run as distributed jobs across HDFS blocks, which is why this setup scales with more DataNodes.
- Airflow lets you run ETL and analytics in separate tasks so multiple steps can run in parallel as the cluster grows.

## Troubleshooting

- If Hive tasks fail, confirm the `hiveserver2` container is healthy and the JDBC driver is present.
- If the Hive connection does not resolve in Airflow, open Admin -> Connections and add a connection:
  - Conn ID: `hiveserver2_default`
  - Conn Type: `Hive Server 2 Thrift`
  - Host: `hiveserver2`
  - Port: `10000`
  - Schema: `default`
  - Login: `hive`
- If Airflow cannot write logs on Linux, set `AIRFLOW_UID` before starting:

```bash
export AIRFLOW_UID=$(id -u)
```

## Cleanup

Stop all containers and keep data:

```bash
docker compose down
docker compose -f docker-compose.yml -f docker-compose.airflow.yml down
```

Full reset (wipe HDFS and metastore data):

```bash
docker compose down -v
```

Full reset for both stacks (including Airflow volumes):

```bash
docker compose -f docker-compose.yml -f docker-compose.airflow.yml down -v
```
