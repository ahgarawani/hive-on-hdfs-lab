# Hive Modern Lab

A robust, Docker-based Apache Hive 4.0 learning environment featuring the **MovieLens** dataset. Designed for data engineering experimentation, SQL analytics learning, and exploring the Hadoop/Hive ecosystem without complex cluster setup.

## 🏗️ Architecture Stack

| Component         | Version | Role                          | URL (if applicable)                |
| :---------------- | :------ | :---------------------------- | :--------------------------------- |
| **Apache Hive**   | 4.0.1   | Data Warehousing & SQL Engine | `http://localhost:10002` (Web UI)  |
| **Apache Hadoop** | 3.4.1   | Distributed Storage (HDFS)    | `http://localhost:9870` (NameNode) |
| **Hue**           | 4.11.0  | SQL Workbench & HDFS Browser  | `http://localhost:8888`            |
| **PostgreSQL**    | 16      | Metastore Backend             | -                                  |

---

## 🚀 Quick Start

### 1. Prerequisites

- Docker & Docker Compose
- 8GB+ RAM available (Containers allocate ~4-6GB)

### 2. Start the Cluster

Launch the environment. This starts NameNode, DataNodes, Metastore, HiveServer2, and Hue.

```bash
docker compose up -d
```

> ⏳ **Wait 1-2 minutes** for all services to become healthy. Run `docker ps` to verify.

### 3. Load Data & Create Schema

The project includes automated scripts to download the MovieLens dataset, ingest it into HDFS, and create optimized Hive tables.

**Step A: Ingest Data (Run from Host)**
Downloads the dataset and uploads it to HDFS (`/user/hive/warehouse/movielens.db/...`).

```bash
./scripts/load_data.sh
```

**Step B: Build Data Warehouse**
Creates the Hive database, staging tables (CSV), and optimized analytical tables (ORC + Snappy).

```bash
docker exec hiveserver2 hive -f /scripts/create_tables.hql
```

---

## 📊 Dataset: MovieLens (Latest Small)

We use the industry-standard [MovieLens Dataset](https://grouplens.org/datasets/movielens/) for realistic analytics scenarios.

### Schema Overview

| Table Layer   | Table Name          | Format  | Description                                       |
| :------------ | :------------------ | :------ | :------------------------------------------------ |
| **Staging**   | `movies_raw`        | CSV     | Raw movie metadata (ID, Title, Genres)            |
| **Staging**   | `ratings_raw`       | CSV     | Raw user ratings (User, Movie, Rating, Timestamp) |
| **Warehouse** | `movies`            | **ORC** | Optimized storage with Snappy compression         |
| **Warehouse** | `ratings`           | **ORC** | Bucketed by `user_id`, sorted by time             |
| **Analytics** | `ratings_analytics` | **ORC** | Converted timestamps and partitioned structure    |

---

## 🧑‍💻 Learning & Exploration

### Running Queries

You can run HiveQL queries via the command line or the Hue Web UI.

**Option 1: Command Line**

```bash
# Run the included sample queries suite
docker exec hiveserver2 hive -f /scripts/sample_queries.hql

# Opens interactive Hive shell
docker exec -it hiveserver2 hive
```

**Option 2: Hue Web UI (Recommended)**

1. Go to [http://localhost:8888](http://localhost:8888).
2. Create any username/password (first login is admin).
3. Open the **Editor -> Hive**.
4. Run: `SELECT * FROM movielens.movies LIMIT 10;`

### Advanced Concepts Demonstrated

The scripts provided in this repo (`scripts/`) demonstrate real-world patterns:

- **ETL Pipeline**: `load_data.sh` handles the extract (download) and load (HDFS put). `create_tables.hql` handles the transformation (INSERT OVERWRITE).
- **Storage Optimization**: Use of **ORC** format and **Snappy** compression for performance.
- **Complex Types**: Handling array-like strings (`Action|Adventure`) using `LATERAL VIEW EXPLODE`.
- **Window Functions**: Using `DENSE_RANK()` for top-N analysis.
- **Bucketing**: Optimizing joins by clustering data.

---

## 📂 Project Structure

```
├── config/              # Configuration files
│   ├── hive-site.xml    # Hive connection settings
│   ├── core-site.xml    # Hadoop core settings
│   ├── hdfs-site.xml    # HDFS replication & webhdfs
│   └── hue.ini          # Hue interface config
├── scripts/             # ETL & SQL Scripts
│   ├── load_data.sh     # Automation script for data ingestion
│   ├── create_tables.hql# DDL for Staging & Warehouse layers
│   └── sample_queries.hql # Analytical queries for learning
├── datasets/            # Local cache for downloaded data
└── docker-compose.yml   # Cluster definition
```

## 🛠 Troubleshooting

- **Hue File Browser Error?** Ensure `webhdfs` is enabled. We have mapped `hdfs-site.xml` to Hue to support this.
- **HDFS Access Issues?** The containers are configured to communicate on `hive-network`. If `hdfs dfs -ls /` fails inside `hiveserver2`, check if `core-site.xml` is mounted correctly (Fixed in latest version).
- **Performance?** Increase Docker memory limit if queries hang. HiveServer2 is set to use 2GB Heap (`-Xmx2G`).
