#!/bin/bash
#
# video_to_gsplat.sh
#
# Author: Nandan Manjunatha nannigalaxy@gmail.com
# License: MIT
# Description:
#   This script extracts frames from a video at a specified FPS,
#   runs Structure-from-Motion (SfM) using COLMAP, and then trains Speedy-Splat model.
#
# Usage:
#   ./video_to_gsplat.sh <fps> <input_video_path> <sfm_output_dir> <gsplat_output_dir_path>
#

# Check if enough arguments are passed
if [ "$#" -ne 4 ]; then
    echo "Usage: $0 <fps> <input_video_path> <sfm_output_dir> <gsplat_output_dir_path>"
    exit 1
fi

# Read command-line arguments
FPS="$1"
INPUT_VIDEO="$2"
SFM_OUTPUT_DIR="$3"
GSPLAT_OUTPUT_DIR="$4"

ENABLE_GPU="1" # Default: GPU enabled

# Create necessary directories
mkdir -p "$SFM_OUTPUT_DIR/images"

###########################################
# Step 1: Extract Frames from Video
###########################################
echo "Extracting frames from video at $FPS FPS..."
ffmpeg -i "$INPUT_VIDEO" -vf "fps=$FPS" "$SFM_OUTPUT_DIR/images/frame_%04d.png" && \

###########################################
# Step 2: Run COLMAP SfM and Export Undistorted Model
###########################################
echo "Running COLMAP SfM pipeline..."
./colmap_undistorted_sfm_export.sh "$SFM_OUTPUT_DIR/images" "$SFM_OUTPUT_DIR" ${ENABLE_GPU:+--enable_gpu} && \

###########################################
# Step 3: Train GSplat Model
###########################################
echo "Training 3D GS..."

./train_speedy_splat.sh $SFM_OUTPUT_DIR/undistorted $SFM_OUTPUT_DIR
