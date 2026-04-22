#!/bin/bash

STATE_FILE="/tmp/mouse_frozen"
PID_FILE="/tmp/mouse_freeze_pid"
POS_FILE="/tmp/mouse_freeze_pos"
THEME_FILE="/tmp/mouse_freeze_theme"

# Standard-Theme (wird verwendet wenn kein anderes Theme gesetzt ist)
DEFAULT_THEME="Adwaita"
DEFAULT_SIZE="24"

if [ -f "$STATE_FILE" ]; then
    # Entsperren
    if [ -f "$PID_FILE" ]; then
        kill $(cat "$PID_FILE") 2>/dev/null
        rm "$PID_FILE"
    fi

    # Zurück zum ursprünglichen Cursor-Theme
    if [ -f "$THEME_FILE" ]; then
        THEME_INFO=$(cat "$THEME_FILE")
        hyprctl setcursor $THEME_INFO
        rm "$THEME_FILE"
    else
        hyprctl setcursor "$DEFAULT_THEME" "$DEFAULT_SIZE"
    fi

    rm "$STATE_FILE"
    rm "$POS_FILE" 2>/dev/null
    notify-send "Maus entsperrt" -t 1000
else
    # Aktuelle Position speichern
    hyprctl cursorpos | tr -d ',' > "$POS_FILE"

    # Aktuelles Theme speichern (verwende Default falls nicht gesetzt)
    echo "$DEFAULT_THEME $DEFAULT_SIZE" > "$THEME_FILE"

    # Zu unsichtbarem Cursor wechseln
    hyprctl setcursor "invisible-cursor" 24

    touch "$STATE_FILE"

    # Cursor an aktueller Position halten (eingefroren)
    (while [ -f "$STATE_FILE" ]; do
        if [ -f "$POS_FILE" ]; then
            POS=$(cat "$POS_FILE")
            hyprctl dispatch movecursor $POS
        fi
        sleep 0.005
    done) &

    echo $! > "$PID_FILE"
    notify-send "Maus unsichtbar + eingefroren (Scroll aktiv)" -t 1000
fi
