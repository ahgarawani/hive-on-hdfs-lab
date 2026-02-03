#!/bin/bash
# =============================================================================
# Hive Modern Lab - HDFS Data Loader
# =============================================================================
# Description: Uploads the local MovieLens dataset to HDFS.
# =============================================================================

set -e

# Configuration
HDFS_ROOT_DIR="/user/hive/warehouse/movielens.db"
CONTAINER_EXEC="docker exec hiveserver2" # Using HiveServer2 as the edge node for HDFS commands

echo "======================================================="
echo " 🏗️  Hive Modern Lab: HDFS Data Loader"
echo "======================================================="

# -----------------------------------------------------------------------------
# 1. Wait for HDFS
# -----------------------------------------------------------------------------
echo "[1/3] Verifying HDFS connectivity..."

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
# 2. Create HDFS Structure
# -----------------------------------------------------------------------------
echo "[2/3] Creating HDFS Directory Structure..."

# Create database directory and table partitions
$CONTAINER_EXEC hdfs dfs -mkdir -p "$HDFS_ROOT_DIR/movies_raw"
$CONTAINER_EXEC hdfs dfs -mkdir -p "$HDFS_ROOT_DIR/ratings_raw"
$CONTAINER_EXEC hdfs dfs -mkdir -p "$HDFS_ROOT_DIR/tags_raw"
$CONTAINER_EXEC hdfs dfs -mkdir -p "$HDFS_ROOT_DIR/links_raw"

# Ensure permissions (Simplifying for lab environment)
$CONTAINER_EXEC hdfs dfs -chmod -R 777 /user/hive

# -----------------------------------------------------------------------------
# 3. Upload Data to HDFS
# -----------------------------------------------------------------------------
echo "[3/3] Ingesting Data to HDFS..."

# Note: The ./datasets folder on Host is mounted to /datasets in the Container
# We use the internal path /datasets/ml-latest-small/... for the put command

$CONTAINER_EXEC hdfs dfs -put -f /datasets/ml-latest-small/movies.csv  "$HDFS_ROOT_DIR/movies_raw/"
$CONTAINER_EXEC hdfs dfs -put -f /datasets/ml-latest-small/ratings.csv "$HDFS_ROOT_DIR/ratings_raw/"
$CONTAINER_EXEC hdfs dfs -put -f /datasets/ml-latest-small/tags.csv    "$HDFS_ROOT_DIR/tags_raw/"
$CONTAINER_EXEC hdfs dfs -put -f /datasets/ml-latest-small/links.csv   "$HDFS_ROOT_DIR/links_raw/"

echo "======================================================="
echo "🎉 Data Load Success!"
echo "   HDFS Location: $HDFS_ROOT_DIR"
echo "======================================================="
