#!/usr/bin/env bash
# Webcam-Vorschau toggle: oeffnet oder schliesst ein schwebendes Webcam-Fenster
# Input: /dev/video0
# Output: mpv-Fenster mit Titel "webcam-float"

WINDOW_TITLE="webcam-float"
DEVICE="/dev/video0"

if pgrep -f "title=${WINDOW_TITLE}" > /dev/null 2>&1; then
    pkill -f "title=${WINDOW_TITLE}"
else
    mpv \
        --title="${WINDOW_TITLE}" \
        --no-border \
        --ontop \
        --keepaspect \
        --no-osc \
        --no-input-default-bindings \
        --profile=low-latency \
        --untimed \
        --demuxer-lavf-format=video4linux2 \
        --demuxer-lavf-o=input_format=mjpeg \
        --script="${HOME}/.config/hypr/scripts/webcam-flip.lua" \
        "av://v4l2:${DEVICE}" &
fi
