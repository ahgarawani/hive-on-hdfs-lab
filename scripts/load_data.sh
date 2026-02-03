#!/bin/bash
# =============================================================================
# Hive Modern Lab - Data Loader Script
# =============================================================================
# Dataset: MovieLens Latest Small
# Description: Downloads and uploads the MovieLens dataset to HDFS.
#              Designed to be run from the HOST machine (not inside container).
# Use Case: Demonstrates "ETL" ingestion from Local -> HDFS using Docker wrappers.
# =============================================================================

set -e

# Configuration
DATASET_URL="https://files.grouplens.org/datasets/movielens/ml-latest-small.zip"
LOCAL_DATA_DIR="./datasets"
MOVIELENS_DIR="$LOCAL_DATA_DIR/ml-latest-small"
HDFS_ROOT_DIR="/user/hive/warehouse/movielens.db"
CONTAINER_EXEC="docker exec hiveserver2" # Using HiveServer2 as the edge node for HDFS commands

echo "======================================================="
echo " 🏗️  Hive Modern Lab: MovieLens Data Loader"
echo "======================================================="

# -----------------------------------------------------------------------------
# 1. Download Dataset (Host Side)
# -----------------------------------------------------------------------------
echo "[1/4] Checking local dataset..."

if [ ! -d "$MOVIELENS_DIR" ]; then
    echo "  ⬇️  Downloading MovieLens dataset from GroupLens..."
    mkdir -p "$LOCAL_DATA_DIR"
    
    # Check if wget is available
    if command -v wget &> /dev/null; then
        wget -q --show-progress -O "$LOCAL_DATA_DIR/movielens.zip" "$DATASET_URL"
    elif command -v curl &> /dev/null; then
        curl -L -o "$LOCAL_DATA_DIR/movielens.zip" "$DATASET_URL"
    else
        echo "  ❌ Error: Neither wget nor curl found. Please install one to download data."
        exit 1
    fi

    echo "  📦 Unzipping archive..."
    unzip -q -o "$LOCAL_DATA_DIR/movielens.zip" -d "$LOCAL_DATA_DIR/"
    rm "$LOCAL_DATA_DIR/movielens.zip"
    echo "  ✅ Download complete."
else
    echo "  ✅ Dataset already exists at $MOVIELENS_DIR"
fi

# -----------------------------------------------------------------------------
# 2. Wait for HDFS
# -----------------------------------------------------------------------------
echo "[2/4] Verifying HDFS connectivity..."

MAX_RETRIES=30
for ((i=1; i<=MAX_RETRIES; i++)); do
    if $CONTAINER_EXEC hdfs dfs -test -e / > /dev/null 2>&1; then
        echo "  ✅ HDFS is healthy and accessible."
        break
    fi
    echo "  ⏳ Waiting for HDFS (attempt $i/$MAX_RETRIES)..."
    sleep 5
    if [ $i -eq $MAX_RETRIES ]; then
        echo "  ❌ HDFS timed out. Please check container logs."
        exit 1
    fi
done

# -----------------------------------------------------------------------------
# 3. Create HDFS Structure
# -----------------------------------------------------------------------------
echo "[3/4] Creating HDFS Directory Structure..."

# Create database directory and table partitions
$CONTAINER_EXEC hdfs dfs -mkdir -p "$HDFS_ROOT_DIR/movies_raw"
$CONTAINER_EXEC hdfs dfs -mkdir -p "$HDFS_ROOT_DIR/ratings_raw"
$CONTAINER_EXEC hdfs dfs -mkdir -p "$HDFS_ROOT_DIR/tags_raw"
$CONTAINER_EXEC hdfs dfs -mkdir -p "$HDFS_ROOT_DIR/links_raw"

# Ensure permissions (Simplifying for lab environment)
$CONTAINER_EXEC hdfs dfs -chmod -R 777 /user/hive

# -----------------------------------------------------------------------------
# 4. Upload Data to HDFS
# -----------------------------------------------------------------------------
echo "[4/4] Ingesting Data to HDFS..."

# Note: The ./datasets folder on Host is mounted to /datasets in the Container
# We use the internal path /datasets/ml-latest-small/... for the put command

$CONTAINER_EXEC hdfs dfs -put -f /datasets/ml-latest-small/movies.csv  "$HDFS_ROOT_DIR/movies_raw/"
$CONTAINER_EXEC hdfs dfs -put -f /datasets/ml-latest-small/ratings.csv "$HDFS_ROOT_DIR/ratings_raw/"
$CONTAINER_EXEC hdfs dfs -put -f /datasets/ml-latest-small/tags.csv    "$HDFS_ROOT_DIR/tags_raw/"
$CONTAINER_EXEC hdfs dfs -put -f /datasets/ml-latest-small/links.csv   "$HDFS_ROOT_DIR/links_raw/"

echo "======================================================="
echo "🎉 Data Load Success!"
echo "   HDFS Location: $HDFS_ROOT_DIR"
echo "   Next Step: Run 'docker exec -it hiveserver2 hive -f /scripts/create_tables.hql'"
echo "======================================================="
