#!/bin/bash

# Download NYC TLC Yellow Taxi Trip Data
# This is a popular large dataset for learning SQL analytics
# Each file is ~100-400MB with millions of rows

set -e

DATASET_DIR="$(dirname "$0")/../datasets"
mkdir -p "$DATASET_DIR"

# Default to 2023 data, can be overridden
YEAR="${1:-2023}"
MONTHS="${2:-1}"  # Number of months to download (1-12)

echo "========================================"
echo "NYC Yellow Taxi Trip Data Downloader"
echo "========================================"
echo "Year: $YEAR"
echo "Months to download: $MONTHS"
echo ""

BASE_URL="https://d37ci6vzurychx.cloudfront.net/trip-data"

for ((month=1; month<=MONTHS; month++)); do
    MONTH_PADDED=$(printf "%02d" $month)
    FILENAME="yellow_tripdata_${YEAR}-${MONTH_PADDED}.parquet"
    URL="${BASE_URL}/${FILENAME}"
    OUTPUT="${DATASET_DIR}/${FILENAME}"
    
    if [ -f "$OUTPUT" ]; then
        echo "✓ $FILENAME already exists, skipping..."
    else
        echo "⬇ Downloading $FILENAME..."
        curl -L -o "$OUTPUT" "$URL"
        echo "✓ Downloaded $FILENAME ($(du -h "$OUTPUT" | cut -f1))"
    fi
done

echo ""
echo "========================================"
echo "Download complete!"
echo "Files saved to: $DATASET_DIR"
echo ""
ls -lh "$DATASET_DIR"/*.parquet 2>/dev/null || echo "No parquet files found"
echo "========================================"
