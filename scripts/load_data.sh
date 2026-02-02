#!/bin/bash

# Load NYC Taxi data into Hive
# Run this inside the hive-server container

set -e

echo "========================================"
echo "Loading NYC Taxi Data into Hive"
echo "========================================"

# Create warehouse directory structure
echo "Creating warehouse directories..."
mkdir -p /opt/hive/data/warehouse/nyc_taxi.db/yellow_trips

# Copy parquet files to warehouse
echo "Copying parquet files to Hive warehouse..."
if ls /datasets/*.parquet 1> /dev/null 2>&1; then
    cp /datasets/*.parquet /opt/hive/data/warehouse/nyc_taxi.db/yellow_trips/
    echo "✓ Parquet files copied"
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

# Run table creation
echo "Creating Hive tables..."
beeline -u "jdbc:hive2://localhost:10000/" -f /scripts/create_tables.hql

# Load taxi zones data
echo "Loading taxi zones data..."
beeline -u "jdbc:hive2://localhost:10000/" -e "
USE nyc_taxi;
LOAD DATA LOCAL INPATH '/datasets/taxi_zone_lookup.csv' OVERWRITE INTO TABLE taxi_zones;
"

echo ""
echo "========================================"
echo "Data loading complete!"
echo ""
echo "Sample query to verify:"
echo "  SELECT COUNT(*) FROM nyc_taxi.yellow_trips;"
echo "========================================"
