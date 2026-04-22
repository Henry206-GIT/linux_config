#!/usr/bin/env bash
# Startet tty-clock mit automatischer Schriftgroessen-Skalierung via Kitty Remote-Control
# Input: Fenster-Pixelbreite via hyprctl clients, optionale tty-clock Flags als Argumente
# Output: tty-clock mit dynamisch angepasster Schriftgroesse

BASE_FONT=6
MIN_FONT=5
BASE_WIDTH=400
LAST_FONT=0
ADJUSTING=0
EXTRA_FLAGS=("$@")
pid=""

# Liest aktuelle Fensterbreite in Pixeln via hyprctl
# Input: keine
# Output: Pixelbreite als Ganzzahl
get_pixel_width() {
    python3 -c "
import subprocess, json, sys
try:
    out = subprocess.check_output(['hyprctl','clients','-j'], text=True)
    for c in json.loads(out):
        if c.get('class') == 'clock-float':
            print(c['size'][0])
            sys.exit()
except:
    pass
print($BASE_WIDTH)
" 2>/dev/null
}

# Berechnet optimale Schriftgroesse und setzt sie via kitty, startet tty-clock neu
# Input: Pixelbreite des Fensters
# Output: Schriftgroesse angepasst, tty-clock Prozess gestartet
apply_font() {
    [[ $ADJUSTING -eq 1 ]] && return
    ADJUSTING=1

    local width font
    width=$(get_pixel_width)
    font=$(( BASE_FONT * width / BASE_WIDTH ))
    [[ $font -lt $MIN_FONT ]] && font=$MIN_FONT

    if [[ $font -ne $LAST_FONT ]]; then
        LAST_FONT=$font
        kitty @ set-font-size "$font" 2>/dev/null
        [[ -n "$pid" ]] && kill "$pid" 2>/dev/null
        sleep 0.3
        clear
        tty-clock -c "${EXTRA_FLAGS[@]}" &
        pid=$!
    fi

    ADJUSTING=0
}

# Raeumt auf und setzt Schriftgroesse zurueck
# Input: pid des laufenden tty-clock Prozesses
# Output: keine
cleanup() {
    [[ -n "$pid" ]] && kill "$pid" 2>/dev/null
    kitty @ set-font-size 0 2>/dev/null
    exit 0
}

trap 'apply_font' WINCH
trap 'cleanup' EXIT INT TERM

apply_font

while true; do
    wait "$pid" 2>/dev/null
    kill -0 "$pid" 2>/dev/null || break
done
