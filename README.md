# Hive On HDFS Lab

A robust, Docker-based Apache Hive 4.0 learning environment featuring the **MovieLens** dataset. Designed for data engineering experimentation, SQL analytics learning, and exploring the Hadoop/Hive ecosystem without complex cluster setup.

## 🏗️ Architecture Stack

The lab simulates a real-world big data cluster. Each component runs in its own Docker container, mimicking a distributed environment.

| Component              | Container Name | Version | Role             | Description                                                                                                | URL                      |
| :--------------------- | :------------- | :------ | :--------------- | :--------------------------------------------------------------------------------------------------------- | :----------------------- |
| **Apache Hive Server** | `hiveserver2`  | 4.0.1   | SQL Engine       | The "Brain". Accepts SQL queries, compiles them into execution plans, and runs them over the data in HDFS. | `http://localhost:10002` |
| **Hive Metastore**     | `metastore`    | 4.0.1   | Metadata Service | The "Catalog". Stores schema definitions (table names, columns, locations) but not the actual data.        | -                        |
| **PostgreSQL**         | `postgres`     | 16      | Metastore DB     | The "Library Card Catalog". The backing database where the Metastore service saves its information.        | -                        |
| **Hadoop NameNode**    | `namenode`     | 3.4.1   | HDFS Master      | The "Directory". Knows where every file block is stored across the cluster.                                | `http://localhost:9870`  |
| **Hadoop DataNode**    | `datanode`     | 3.4.1   | HDFS Worker      | The "Hard Drive". Stores the actual blocks of data (files).                                                | -                        |
| **Hue**                | `hue`          | 4.11.0  | Web Interface    | The "Frontend". A visual UI for writing SQL queries and browsing HDFS files.                               | `http://localhost:8888`  |

### How they work together:

1.  **Storage:** Data (CSVs, ORC files) lives in `datanode`, managed by `namenode`.
2.  **Metadata:** When a table is created, `hiveserver2` tells `metastore` to record the schema in `postgres`.
3.  **Compute:** When a query runs, `hiveserver2` looks up the file location from `metastore`, reads data from `namenode`/`datanode`, processes it, and returns results.
4.  **Interface:** Users interact with the system via `hue` (web) or the command line, which talks to `hiveserver2`.

---

## 🚀 Quick Start Guide

### 1. Prerequisites

Before beginning, ensure the following are installed:

- **Docker Desktop**: [Installation Guide](https://docs.docker.com/get-docker/)
- **Docker Compose**: [Installation Guide](https://docs.docker.com/compose/install/)
- **Bash Shell**: Git Bash (Windows), Terminal (Mac/Linux).
- **curl** or **wget**: To download drivers and datasets.
- **8GB+ RAM**: The containers require significant memory.

### 2. Download the Repository

Clone this repository to your local machine:

```bash
git clone https://github.com/your-username/hive-on-hdfs-lab.git
cd hive-on-hdfs-lab
```

OR download the ZIP and extract it.

### 3. Initialization

**Step A: Change Permissions of Scripts**

```bash
chmod +x ./scripts/*
```

**Step B: Download Database Driver**
Binary drivers are not shipped in the repository. Run this script to download the PostgreSQL JDBC driver required for Hive to talk to the Metastore.

```bash
./scripts/download_driver.sh
```

**Step C: Start the Cluster**
Launch the environment. This starts NameNode, DataNodes, Metastore, HiveServer2, and Hue.

```bash
docker compose up -d
```

> ⏳ **Wait 1-2 minutes** for all services to become healthy. Check the status with `docker ps`.

### 4. Data Strategy (Extract & Load)

This lab is pre-configured to use the **MovieLens Latest Small** dataset. This dataset was chosen to demonstrate complex SQL operations like joins, window functions, and array handling.

**Step C: Download Dataset**
Download the MovieLens zip file and extract it to a local `datasets/` folder.

```bash
./scripts/download_dataset.sh
```

**Step D: Load Data into HDFS (Automated)**
This step mimics an "Ingestion" pipeline. It uploads the local CSV files into the Hadoop Distributed File System (HDFS) inside the cluster.

```bash
./scripts/load_data_to_hdfs.sh
```

#### Manual Data Loading (Optional)

If prefering to load data manually without the script:

1.  Ensure the dataset is downloaded to `datasets/ml-latest-small`.
2.  The `hiveserver2` container mounts this folder at `/dataset`.
3.  Log in to the container and upload files using the HDFS CLI:

```bash
# 1. Enter the Hive container
docker exec -it hiveserver2 bash

# 2. Create directory in HDFS
hdfs dfs -mkdir -p /user/hive/warehouse/movielens.db/movies_raw

# 3. Upload file from local mount to HDFS
hdfs dfs -put /datasets/ml-latest-small/movies.csv /user/hive/warehouse/movielens.db/movies_raw/
```

---

## 💻 Interacting with HDFS

There are three ways to explore the filesystem:

1.  **Terminal (CLI):** Run HDFS commands directly inside the container.

    ```bash
    docker exec hiveserver2 hdfs dfs -ls /user/hive/warehouse
    ```

2.  **Hadoop Web UI:** View the NameNode status and browse files via the browser.
    - URL: [http://localhost:9870](http://localhost:9870)
    - Navigate to **Utilities** -> **Browse the file system**.

3.  **Hue File Browser:** A user-friendly file manager.
    - URL: [http://localhost:8888](http://localhost:8888)
    - Click the **Files** icon on the left sidebar.

---

## 📊 Analytics & Usage

### 4. Build the Data Warehouse

Now that the raw CSVs are in HDFS, use Hive to build a proper Data Warehouse structure.

**Option A: Automated Script**
Run the prepared Hive scripts (`.hql`) to create tables and perform ETL.

```bash
docker exec hiveserver2 hive -f /scripts/01_setup_staging.hql
docker exec hiveserver2 hive -f /scripts/02_etl_warehouse.hql
```

**Option B: Manual Execution (Beeline)**
Connect to the Hive server interactively using Beeline (the JDBC CLI tool) and run queries manually.

```bash
# Connect to HiveServer2
docker exec -it hiveserver2 beeline -u jdbc:hive2://localhost:10000 -n hive

# Inside the Beeline shell:
> CREATE DATABASE IF NOT EXISTS movielens;
> USE movielens;
> SHOW TABLES;
```

**Option C: Manual Execution (Hue)**

1.  Go to [http://localhost:8888](http://localhost:8888).
2.  Open the **Editor** -> **Hive**.
3.  Paste SQL commands from `scripts/01_setup_staging.hql` into the editor and click **Run**.

### 5. Run Analysis

Prepare to run analytical queries sample business questions (e.g., "Top rated movies", "Most active users").

**via Command Line:**

```bash
docker exec hiveserver2 hive -f /scripts/03_analytics.hql
```

**via Hue (Recommended):**

1.  Go to **Hue**.
2.  Try a query:
    ```sql
    SELECT * FROM movielens.ratings_analytics LIMIT 10;
    ```

---

## 🧹 Reset & Cleanup

### Understanding Volumes

All data (HDFS storage, Metastore database) is persisted in Docker Volumes (`namenode_data`, `datanode_data`, `postgres_data`). This means if stopping the containers, the data is saved.

### Stop the Cluster (Keep Data)

To stop the containers but preserve the database and HDFS files:

```bash
docker compose down
```

### Full Reset (Wipe Data)

To completely wipe the cluster and start fresh (deleting all data and tables), run:

```bash
docker compose down -v
```

_The `-v` flag deletes the volumes._

## 📂 Project Structure

```
├── config/              # Configuration files (Hive, Hadoop, Hue)
├── scripts/             # Automation Scripts
│   ├── download_driver.sh      # Setup: Gets Postgres JDBC driver
│   ├── download_dataset.sh     # ETL: Downloads MovieLens data
│   ├── load_data_to_hdfs.sh    # ETL: Uploads data to HDFS
│   ├── 01_setup_staging.hql    # SQL: DDL for CSV tables
│   ├── 02_etl_warehouse.hql    # SQL: DDL/DML for ORC tables
│   └── 03_analytics.hql        # SQL: Sample analysis
├── datasets/            # Local cache for downloaded data (Ignored by Git)
├── drivers/             # JDBC drivers (Ignored by Git)
└── docker-compose.yml   # Cluster definition
```
