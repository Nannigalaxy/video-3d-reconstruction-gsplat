#!/bin/bash
#
# train_speedy_splat.sh
#
# Author: Nandan Manjunatha nannigalaxy@gmail.com
# License: MIT
# Description:
#   This script runs the Speedy Splat training process using images from the
#   SfM pipeline and saves the trained model to a specified directory.
#
# Usage:
#   ./train_speedy_splat.sh <sfm_output_dir> <gsplat_output_dir_path>
#

# Check if enough arguments are passed
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <sfm_input_dir> <gsplat_output_dir_path>"
    exit 1
fi

# Read command-line arguments
SFM_INPUT_DIR="$1"  # Directory containing undistorted images from SfM
GSPLAT_OUTPUT_DIR="$2"  # Directory to save the output model

# Create necessary directories if they don't exist
mkdir -p "$GSPLAT_OUTPUT_DIR"

echo "Running Speedy Splat training..."

python speedy-splat/train.py \
    --source_path "$SFM_INPUT_DIR" \
    --model_path "$GSPLAT_OUTPUT_DIR" \
    --resolution 1024 \
    --iterations 10000 \
    --position_lr_init 0.001 \
    --position_lr_final 0.0001 \
    --feature_lr 0.0001 \
    --scaling_lr 0.0001 \
    --rotation_lr 0.0001 \
    --percent_dense 0.8 \
    --lambda_dssim 0.5 \
    --densification_interval 1000 \
    --checkpoint_iterations 500 \
    --eval \
    --debug \
    --visualize_iterations 1000 \
    --save_iterations 2000
