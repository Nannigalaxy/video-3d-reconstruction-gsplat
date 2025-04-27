#!/bin/bash
#
# colmap_undistorted_sfm_export.sh
#
# Author: Nandan Manjunatha nannigalaxy@gmail.com
# License: MIT
# Description: 
#   This script automates the COLMAP pipeline for feature extraction, matching,
#   sparse reconstruction, image undistortion, and model export.
#
# Usage:
#   ./colmap_undistorted_sfm_export.sh <input_images> <output_dir> [--exhaustive] [--enable_gpu]
#

# Check if minimum required arguments are passed
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <input_images> <output_dir> [--exhaustive] [--enable_gpu]"
    exit 1
fi

# Read required arguments
INPUT_IMAGES=$1
OUTPUT_DIR=$2

# Default values
MATCHER_MODE="sequence"  # Default matcher mode
ENABLE_GPU="1"           # Default: GPU enabled

# Parse optional arguments
shift 2
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --exhaustive) MATCHER_MODE="exhaustive" ;;  # Use exhaustive matching
        --enable_gpu) ENABLE_GPU="1" ;;             # Explicitly enable GPU
        --disable_gpu) ENABLE_GPU="0" ;;             # Optionally disable GPU
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
    shift
done

# Paths
DATABASE_PATH="$OUTPUT_DIR/database.db"
SPARSE_DIR="$OUTPUT_DIR/sparse"
UNDISTORTED_DIR="$OUTPUT_DIR/undistorted"

# Create output directories
mkdir -p "$OUTPUT_DIR"

###########################################
# Step 1: Feature Extraction
###########################################
echo "Running feature extraction (GPU enabled: $ENABLE_GPU)..."
colmap feature_extractor \
    --SiftExtraction.use_gpu=$ENABLE_GPU \
    --database_path "$DATABASE_PATH" \
    --image_path "$INPUT_IMAGES"

###########################################
# Step 2: Feature Matching
###########################################
if [ "$MATCHER_MODE" == "exhaustive" ]; then
    echo "Running exhaustive matcher (GPU enabled: $ENABLE_GPU)..."
    colmap exhaustive_matcher \
        --SiftMatching.use_gpu=$ENABLE_GPU \
        --database_path "$DATABASE_PATH"
else
    echo "Running sequence matcher (GPU enabled: $ENABLE_GPU)..."
    colmap sequential_matcher \
        --SiftMatching.use_gpu=$ENABLE_GPU \
        --database_path "$DATABASE_PATH"
fi

###########################################
# Step 3: Sparse 3D Reconstruction
###########################################
mkdir -p "$SPARSE_DIR"
colmap mapper \
    --database_path "$DATABASE_PATH" \
    --image_path "$INPUT_IMAGES" \
    --output_path "$SPARSE_DIR"

###########################################
# Step 4: Undistort Images
###########################################
mkdir -p "$UNDISTORTED_DIR"
colmap image_undistorter \
    --image_path "$INPUT_IMAGES" \
    --input_path "$SPARSE_DIR/0" \
    --output_path "$UNDISTORTED_DIR" \
    --output_type COLMAP

###########################################
# Step 5: Check and Fix Sparse Directory
###########################################
if [ ! -d "$UNDISTORTED_DIR/sparse/0" ]; then
    echo "sparse/0 not found, checking if sparse/ has data..."

    if [ -d "$UNDISTORTED_DIR/sparse" ] && [ "$(ls -A "$UNDISTORTED_DIR/sparse")" ]; then
        echo "Moving existing sparse/ data into sparse/0/..."
        mkdir -p "$UNDISTORTED_DIR/sparse/0"
        mv "$UNDISTORTED_DIR/sparse/cameras.bin" "$UNDISTORTED_DIR/sparse/images.bin" "$UNDISTORTED_DIR/sparse/points3D.bin" "$UNDISTORTED_DIR/sparse/0/"
        echo "Moved data into sparse/0/"
    else
        echo "ERROR: No data found in sparse/. Undistortion might have failed."
        exit 1
    fi
fi

###########################################
# Optional for debugging
###########################################
mkdir -p "$OUTPUT_DIR/custom_export"

# Export model to PLY
colmap model_converter \
    --input_path "$UNDISTORTED_DIR/sparse/0" \
    --output_path "$OUTPUT_DIR/custom_export/scene.ply" \
    --output_type PLY

# Export model to TXT
colmap model_converter \
    --input_path "$UNDISTORTED_DIR/sparse/0" \
    --output_path "$OUTPUT_DIR/custom_export" \
    --output_type TXT
