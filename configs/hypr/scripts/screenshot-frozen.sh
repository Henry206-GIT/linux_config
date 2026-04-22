#!/bin/bash
# Frozen screenshot mit wayfreeze (wie Windows Snipping Tool)

SCREENSHOT_DIR=~/Pictures/Screenshots
mkdir -p "$SCREENSHOT_DIR"

# Starte wayfreeze (friert den Bildschirm ein - kein Fenster!)
wayfreeze &
FREEZE_PID=$!

# Kurz warten bis freeze aktiv ist
sleep 0.1

# Region auswählen
REGION=$(slurp 2>/dev/null)

# Beende wayfreeze
kill $FREEZE_PID 2>/dev/null
wait $FREEZE_PID 2>/dev/null

# Screenshot der gewählten Region
if [ -n "$REGION" ]; then
    FILENAME="$SCREENSHOT_DIR/screenshot-$(date +%Y%m%d-%H%M%S).png"
    grim -g "$REGION" "$FILENAME"
    notify-send "Screenshot" "Gespeichert: $(basename $FILENAME)" 2>/dev/null
fi
