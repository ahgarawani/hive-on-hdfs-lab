# Hive Modern Lab

A Docker-based Apache Hive 4.0 learning environment with the NYC Yellow Taxi dataset (~3M+ trips per month).

## Stack Versions

| Component   | Version | Image               |
| ----------- | ------- | ------------------- |
| Apache Hive | 4.0.1   | `apache/hive:4.0.1` |
| PostgreSQL  | 16      | `postgres:16`       |
| Hue         | 4.11.0  | `gethue/hue:4.11.0` |

## Quick Start

### 1. Download the Dataset

```bash
# Download 1 month of NYC taxi data (~40-100MB per month, ~3M rows)
./scripts/download_nyc_taxi.sh 2023 1

# Or download 3 months for more data
./scripts/download_nyc_taxi.sh 2023 3
```

### 2. Start the Environment

```bash
docker compose up -d
```

Wait 1-2 minutes for all services to initialize.

### 3. Load Data into Hive

```bash
docker exec -it hive-server bash
chmod +x /scripts/load_data.sh
/scripts/load_data.sh
```

### 4. Access the Services

| Service                | URL                    |
| ---------------------- | ---------------------- |
| **Hue (SQL Editor)**   | http://localhost:8888  |
| **HiveServer2 Web UI** | http://localhost:10002 |

Create an account on first Hue login, then start querying!

## Dataset: NYC Yellow Taxi Trips

The [NYC TLC Trip Record Data](https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page) contains millions of taxi trips with:

- Pickup/dropoff timestamps and locations
- Trip distance and duration
- Fare breakdown (base fare, tips, tolls, surcharges)
- Payment type
- Passenger count

Each monthly file contains **~3 million trips** in Parquet format.

### Tables

| Table          | Description                 | Rows      |
| -------------- | --------------------------- | --------- |
| `yellow_trips` | Trip records                | ~3M/month |
| `taxi_zones`   | Location lookup (263 zones) | 265       |

## Sample Queries

See [scripts/sample_queries.hql](scripts/sample_queries.hql) for 15+ example queries covering:

- Basic aggregations
- Time-based analysis (hourly, daily, day-of-week)
- Location joins with taxi zones
- Tip analysis
- Window functions
- Trip duration analysis

### Quick Examples

```sql
-- Total trips
SELECT COUNT(*) FROM nyc_taxi.yellow_trips;

-- Average fare by payment type
SELECT
    CASE payment_type WHEN 1 THEN 'Credit' WHEN 2 THEN 'Cash' ELSE 'Other' END as payment,
    COUNT(*) as trips,
    ROUND(AVG(total_amount), 2) as avg_fare
FROM nyc_taxi.yellow_trips
GROUP BY payment_type;

-- Top pickup locations
SELECT z.Zone, COUNT(*) as pickups
FROM nyc_taxi.yellow_trips t
JOIN nyc_taxi.taxi_zones z ON t.PULocationID = z.LocationID
GROUP BY z.Zone
ORDER BY pickups DESC
LIMIT 10;
```

## Using Beeline CLI

```bash
docker exec -it hive-server beeline -u "jdbc:hive2://localhost:10000/"
```

## Useful Commands

```bash
# Check service status
docker compose ps

# View Hive logs
docker compose logs -f hive-server

# Restart services
docker compose restart

# Stop and remove volumes
docker compose down -v
```

## Troubleshooting

### Hue connection issues

- Ensure hive-server is running: `docker compose ps`
- Check logs: `docker compose logs hue`
- The first connection may take 30-60 seconds

### Metastore errors

Wait for the metastore health check to pass:

```bash
docker compose ps metastore
```

### No data in tables

Run the data loading script:

```bash
docker exec -it hive-server /scripts/load_data.sh
```

## Project Structure

```
hive-modern-lab/
├── docker-compose.yml          # Docker services
├── config/
│   ├── hue.ini                 # Hue configuration
│   └── init-hue-db.sql         # PostgreSQL init script
├── datasets/                   # Downloaded parquet files
├── scripts/
│   ├── download_nyc_taxi.sh    # Dataset downloader
│   ├── load_data.sh            # Data loader
│   ├── create_tables.hql       # Table definitions
│   └── sample_queries.hql      # Practice queries
└── README.md
```

## Resources

- [Apache Hive 4.0 Documentation](https://hive.apache.org/)
- [NYC TLC Trip Data](https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page)
- [Hive Language Manual](https://cwiki.apache.org/confluence/display/Hive/LanguageManual)
