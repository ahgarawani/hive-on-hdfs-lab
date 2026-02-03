#!/bin/bash
# =============================================================================
# Hive Modern Lab - Dataset Downloader
# =============================================================================
# Dataset: MovieLens Latest Small
# Description: Downloads and extracts the MovieLens dataset locally.
# =============================================================================

set -e

# Configuration
DATASET_URL="https://files.grouplens.org/datasets/movielens/ml-latest-small.zip"
LOCAL_DATA_DIR="./datasets"
MOVIELENS_DIR="$LOCAL_DATA_DIR/ml-latest-small"

echo "======================================================="
echo " 📥 Hive Modern Lab: Dataset Downloader"
echo "======================================================="

if [ -d "$MOVIELENS_DIR" ]; then
    echo "  ✅ Dataset already exists at $MOVIELENS_DIR"
    exit 0
fi

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
