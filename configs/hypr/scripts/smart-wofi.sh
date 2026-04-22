#!/usr/bin/env bash
# Startet Apps via wofi mit Jump-to-Window-Logik fuer Multi-Monitor-Setup.
# App-Liste und Icons werden gecacht und nur bei Aenderungen neu generiert.
# Workspace-Aufteilung: HDMI-A-1 = WS 1-10, DP-1 = WS 11-20, HDMI-A-2 = WS 21-30.

EXCLUDE_FILE="$HOME/.config/hypr/jump-exclude.json"
LOG_FILE="$HOME/.config/hypr/logs/smart-wofi-errors.json"
CACHE_FILE="$HOME/.cache/smart-wofi-apps.tsv"

mkdir -p "$(dirname "$LOG_FILE")" "$(dirname "$CACHE_FILE")"

# Loggt Fehler im JSON-Format
# Input: func, err_type, trace, vars_json | Output: Eintrag in LOG_FILE
log_error() {
    printf '{"timestamp":"%s","function":"%s","error_type":"%s","stack_trace":"%s","variables":%s}\n' \
        "$(date -Iseconds)" "$1" "$2" "$3" "$4" >> "$LOG_FILE"
}

# Prueft ob der App-Cache noch aktuell ist (vergleicht mtime mit App- und Icon-Verzeichnissen)
# Input: keine | Output: Exit 0 = frisch, Exit 1 = veraltet oder fehlt
cache_is_fresh() {
    [[ -f "$CACHE_FILE" ]] || return 1
    local cache_mtime
    cache_mtime=$(stat -c %Y "$CACHE_FILE" 2>/dev/null) || return 1
    for dir in \
        /usr/share/applications \
        "$HOME/.local/share/applications" \
        /usr/share/icons \
        "$HOME/.local/share/icons"; do
        [[ -d "$dir" ]] || continue
        local dir_mtime
        dir_mtime=$(stat -c %Y "$dir" 2>/dev/null) || continue
        [[ "$dir_mtime" -gt "$cache_mtime" ]] && return 1
    done
    return 0
}

# Baut den App-Cache als TSV: AppName \t ExecCmd \t IconPfad
# Icon-Index wird in einem einzigen Scan aller Theme-Verzeichnisse aufgebaut (nicht pro App).
# Input: keine | Output: CACHE_FILE (atomisch geschrieben)
build_cache() {
    python3 - "$CACHE_FILE" <<'PYEOF'
import os, glob, configparser, sys

cache_path = sys.argv[1]

SIZE_PRIO = [
    'scalable', '512x512', '256x256', '192x192', '128x128',
    '96x96', '72x72', '64x64', '48x48', '32x32', '24x24', '22x22', '16x16'
]

# Icon-Index: einmaliger Scan aller Themes und Groessen
# Statt pro App zu globben wird hier ein Woerterbuch {name -> bester_pfad} aufgebaut
icon_index = {}
icon_rank  = {}

for root in ['/usr/share/icons',
             os.path.expanduser('~/.local/share/icons'),
             os.path.expanduser('~/.icons')]:
    if not os.path.isdir(root):
        continue
    for match in glob.glob(os.path.join(root, '*', '*', 'apps', '*')):
        parts = match.split(os.sep)
        if len(parts) < 4:
            continue
        size_dir = parts[-3]
        name, _ = os.path.splitext(os.path.basename(match))
        rank = SIZE_PRIO.index(size_dir) if size_dir in SIZE_PRIO else len(SIZE_PRIO)
        if name not in icon_index or rank < icon_rank[name]:
            icon_index[name] = match
            icon_rank[name]  = rank

# Pixmaps als Fallback in den Index aufnehmen
for match in glob.glob('/usr/share/pixmaps/*'):
    name, ext = os.path.splitext(os.path.basename(match))
    if ext.lower() in ('.png', '.svg', '.xpm', '.jpg') and name not in icon_index:
        icon_index[name] = match

def resolve_icon(raw):
    # Gibt den besten Icon-Pfad fuer einen Icon-Namen oder absoluten Pfad zurueck
    if not raw:
        return ''
    if os.path.isabs(raw):
        return raw if os.path.exists(raw) else ''
    base, ext = os.path.splitext(raw)
    key = base if ext.lower() in ('.png', '.svg', '.xpm', '.jpg') else raw
    return icon_index.get(key, '')

# .desktop-Dateien einlesen und App-Liste aufbauen
seen    = set()
results = []

for d in ['/usr/share/applications', os.path.expanduser('~/.local/share/applications')]:
    if not os.path.isdir(d):
        continue
    for path in sorted(glob.glob(os.path.join(d, '*.desktop'))):
        cp = configparser.ConfigParser(interpolation=None, strict=False)
        try:
            cp.read(path)
        except Exception:
            continue
        if not cp.has_section('Desktop Entry'):
            continue
        e = cp['Desktop Entry']
        if e.get('NoDisplay', '').lower() == 'true':
            continue
        if e.get('Type', 'Application') != 'Application':
            continue
        name      = e.get('Name', '')
        exec_line = e.get('Exec', '')
        if not name or not exec_line or name in seen:
            continue
        seen.add(name)
        results.append(f"{name}\t{exec_line}\t{resolve_icon(e.get('Icon', ''))}")

results.sort()
tmp = cache_path + '.tmp'
with open(tmp, 'w') as f:
    f.write('\n'.join(results) + '\n')
os.replace(tmp, cache_path)
PYEOF
}

# Liest die ausgeschlossenen App-Namen aus jump-exclude.json (lowercase)
# Input: keine | Output: Zeilenweise App-Namen
get_excluded_apps() {
    [[ -f "$EXCLUDE_FILE" ]] || return
    jq -r '.[]' "$EXCLUDE_FILE" 2>/dev/null | tr '[:upper:]' '[:lower:]'
}

# Prueft ob ein Binary-Name in der Ausschlussliste enthalten ist
# Input: binary_name (string) | Output: Exit 0 (ausgeschlossen) oder 1 (nicht)
is_excluded() {
    local app_name
    app_name=$(echo "$1" | tr '[:upper:]' '[:lower:]')
    while IFS= read -r excl; do
        [[ -n "$excl" && "$app_name" == "$excl" ]] && return 0
    done < <(get_excluded_apps)
    return 1
}

# Extrahiert den Basisnamen des Binaries aus einem Exec-Befehl
# Input: exec_cmd (string) | Output: binary_name (string, lowercase)
extract_binary() {
    echo "$1" | sed 's/ %[a-zA-Z]//g' | awk '{print $1}' | xargs basename 2>/dev/null | tr '[:upper:]' '[:lower:]'
}

# Sucht das beste Hyprland-Fenster anhand eines Klassenmusters.
# Filtert versteckte/ungemappte/Spezialworkspace-Fenster, waehlt das groesste.
# Input: pattern (string) | Output: Client-JSON-Objekt oder leer
find_client_by_class() {
    local pattern
    pattern=$(echo "$1" | tr '[:upper:]' '[:lower:]')
    [[ -z "$pattern" ]] && return
    hyprctl clients -j 2>/dev/null | jq -c \
        --arg p "$pattern" \
        '[.[] | select(
            ((.class | ascii_downcase | contains($p)) or
             (.initialClass | ascii_downcase | contains($p))) and
            .mapped == true and .hidden == false and .workspace.id > 0
        )] | sort_by(-(.size[0] * .size[1])) | first // empty' 2>/dev/null
}

# Wechselt zum Workspace des Fensters, fokussiert es und warpt die Maus in die Fenstermitte
# Input: client_json (string) | Output: keine (Hyprland dispatch-Aktionen)
focus_and_warp() {
    local client_json="$1"
    local workspace_id address at_x at_y size_w size_h

    workspace_id=$(echo "$client_json" | jq -r '.workspace.id')
    address=$(echo "$client_json"      | jq -r '.address')
    at_x=$(echo "$client_json"         | jq -r '.at[0]')
    at_y=$(echo "$client_json"         | jq -r '.at[1]')
    size_w=$(echo "$client_json"       | jq -r '.size[0]')
    size_h=$(echo "$client_json"       | jq -r '.size[1]')

    [[ -z "$workspace_id" || "$workspace_id" == "null" ]] && \
        log_error "focus_and_warp" "InvalidData" "focus_and_warp" \
            "{\"client_json\":$(echo "$client_json" | jq -c .)}" && return 1

    hyprctl dispatch workspace "$workspace_id"
    hyprctl dispatch focuswindow "address:$address"
    hyprctl dispatch movecursor $(( at_x + size_w / 2 )) $(( at_y + size_h / 2 ))
}

# Startet eine App anhand ihres Exec-Befehls im Hintergrund
# Input: exec_cmd (string) | Output: keine
launch_app() {
    local exec_cmd
    exec_cmd=$(echo "$1" | sed 's/ %[a-zA-Z]//g')
    eval "$exec_cmd" &
    disown
}

# Hauptfunktion: Cache pruefen, wofi anzeigen, springen oder starten
# Input: keine | Output: keine (Seiteneffekte in Hyprland)
main() {
    # Cache nur neu bauen wenn noetig
    cache_is_fresh || build_cache

    # Wofi-Eingabe direkt aus Cache per awk (schnell, kein Shell-Loop)
    local wofi_input
    wofi_input=$(awk -F'\t' '{
        if ($3 != "") printf "img:%s:text:%s\n", $3, $1
        else print $1
    }' "$CACHE_FILE")

    local selected_raw
    selected_raw=$(echo "$wofi_input" | wofi --show dmenu --allow-images --image-size 32 2>/dev/null)
    [[ -z "$selected_raw" ]] && exit 0

    # "img:/pfad:text:" Prefix entfernen (greedy bis zum letzten :text:)
    local selected_name
    selected_name=$(echo "$selected_raw" | sed 's/.*:text://')

    local exec_line
    exec_line=$(awk -F'\t' -v n="$selected_name" '$1 == n {print $2; exit}' "$CACHE_FILE")

    local binary
    binary=$(extract_binary "$exec_line")

    # App-Name UND Binary gegen Exclude-Liste pruefen
    # (notwendig wenn Binary != App-Name, z.B. Clock startet via kitty)
    if ! is_excluded "$selected_name" && ! is_excluded "$binary"; then
        local client
        client=$(find_client_by_class "$binary")
        if [[ -n "$client" ]]; then
            focus_and_warp "$client"
            exit 0
        fi
    fi

    launch_app "$exec_line"
}

main
