#!/bin/bash

# RTSP URL (change to your camera’s URL)
RTSP_URL="rtsp://192.168.16.11/live/main_stream"

# Save directory
SAVE_DIR="/mnt/ssd/recording"

# Make sure directory exists
mkdir -p "$SAVE_DIR"

# Filename with date + time (YYYY-MM-DD_HH-MM-SS.mp4)
FILENAME="$SAVE_DIR/StartRecord=$(date +'%H:%M:%S\ %d\ %b\ %Y').mp4"

# Run ffmpeg (adjust codec options if needed)
ffmpeg -rtsp_transport tcp -i "$RTSP_URL" -c copy -f mp4 "$FILENAME"