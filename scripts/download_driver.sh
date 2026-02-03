#!/bin/bash
# =============================================================================
# Hive Modern Lab - Driver Downloader
# =============================================================================
# Description: Downloads the PostgreSQL JDBC driver required for Hive Metastore.
# =============================================================================

set -e

DRIVER_VERSION="42.7.3"
DRIVER_JAR="postgresql-${DRIVER_VERSION}.jar"
DRIVER_URL="https://jdbc.postgresql.org/download/${DRIVER_JAR}"
DRIVERS_DIR="./drivers"

echo "======================================================="
echo " 🛠️  Hive Modern Lab: Driver Downloader"
echo "======================================================="

if [ ! -d "$DRIVERS_DIR" ]; then
    mkdir -p "$DRIVERS_DIR"
fi

if [ -f "$DRIVERS_DIR/$DRIVER_JAR" ]; then
    echo "  ✅ Driver $DRIVER_JAR already exists."
    exit 0
fi

echo "  ⬇️  Downloading PostgreSQL JDBC Driver ($DRIVER_VERSION)..."

# Check if wget is available, otherwise use curl
if command -v wget &> /dev/null; then
    wget -q --show-progress -O "$DRIVERS_DIR/$DRIVER_JAR" "$DRIVER_URL"
elif command -v curl &> /dev/null; then
    curl -L -o "$DRIVERS_DIR/$DRIVER_JAR" "$DRIVER_URL"
else
    echo "  ❌ Error: Neither wget nor curl found. Please install one to download the driver."
    exit 1
fi

echo "  ✅ Driver downloaded to $DRIVERS_DIR/$DRIVER_JAR"
