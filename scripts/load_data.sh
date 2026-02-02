#!/bin/bash

# Load NYC Taxi data into Hive via HDFS
# Run this inside the hive-server container

set -e

HADOOP_BIN="/opt/hadoop/bin/hdfs"

echo "========================================"
echo "Loading NYC Taxi Data into Hive (HDFS)"
echo "========================================"

# Wait for HDFS to be ready
echo "Waiting for HDFS..."
for i in {1..30}; do
    if $HADOOP_BIN dfs -ls / > /dev/null 2>&1; then
        echo "✓ HDFS is ready"
        break
    fi
    echo "  Waiting for HDFS... ($i/30)"
    sleep 2
done

# Create HDFS directories
echo "Creating HDFS directories..."
$HADOOP_BIN dfs -mkdir -p /user/hive/warehouse/nyc_taxi.db/yellow_trips
$HADOOP_BIN dfs -mkdir -p /data/taxi_zones
$HADOOP_BIN dfs -chmod -R 777 /user/hive

# Upload parquet files to HDFS
echo "Uploading parquet files to HDFS..."
if ls /datasets/*.parquet 1> /dev/null 2>&1; then
    $HADOOP_BIN dfs -put -f /datasets/*.parquet /user/hive/warehouse/nyc_taxi.db/yellow_trips/
    echo "✓ Parquet files uploaded to HDFS"
else
    echo "⚠ No parquet files found in /datasets"
    echo "  Run scripts/download_nyc_taxi.sh first"
    exit 1
fi

# Download taxi zones lookup if not exists
ZONES_FILE="/datasets/taxi_zone_lookup.csv"
if [ ! -f "$ZONES_FILE" ]; then
    echo "Downloading taxi zones lookup..."
    curl -L -o "$ZONES_FILE" "https://d37ci6vzurychx.cloudfront.net/misc/taxi_zone_lookup.csv"
fi

# Upload taxi zones to HDFS
echo "Uploading taxi zones to HDFS..."
$HADOOP_BIN dfs -put -f "$ZONES_FILE" /data/taxi_zones/

# Run table creation
echo "Creating Hive tables..."
beeline -u "jdbc:hive2://localhost:10000/" -f /scripts/create_tables.hql

# Load taxi zones data
echo "Loading taxi zones data..."
beeline -u "jdbc:hive2://localhost:10000/" -e "
USE nyc_taxi;
LOAD DATA INPATH '/data/taxi_zones/taxi_zone_lookup.csv' OVERWRITE INTO TABLE taxi_zones;
"

echo ""
echo "========================================"
echo "Data loading complete!"
echo ""
echo "HDFS contents:"
$HADOOP_BIN dfs -ls -R /user/hive/warehouse/nyc_taxi.db/
echo ""
echo "Sample query to verify:"
echo "  SELECT COUNT(*) FROM nyc_taxi.yellow_trips;"
echo "========================================"
echo "========================================"
