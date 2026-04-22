#!/bin/bash

# Ermittelt relativen Workspace (1-10) für einen Monitor
# Input: Workspace ID (1-30), Monitor Name
# Output: Relativer Workspace (1-10)
get_relative_workspace() {
    local ws_id=$1
    local monitor_name=$2

    case "$monitor_name" in
        "HDMI-A-1")
            echo $((ws_id))
            ;;
        "DP-1")
            echo $((ws_id - 10))
            ;;
        "HDMI-A-2")
            echo $((ws_id - 20))
            ;;
        *)
            echo "?"
            ;;
    esac
}

# Ermittelt aktiven Workspace für jeden Monitor
# Input: -
# Output: JSON für waybar
get_all_workspaces() {
    local display_text=""

    # Hole Monitor-Informationen mit aktivem Workspace
    local monitors_json=$(hyprctl monitors -j)

    # Verarbeite jeden Monitor
    for monitor_name in "HDMI-A-1" "DP-1" "HDMI-A-2"; do
        # Finde den aktiven Workspace für diesen Monitor
        local active_ws=$(echo "$monitors_json" | jq -r --arg mon "$monitor_name" '.[] | select(.name == $mon) | .activeWorkspace.id')

        # Fallback falls Monitor nicht gefunden
        if [ -z "$active_ws" ] || [ "$active_ws" == "null" ]; then
            case "$monitor_name" in
                "HDMI-A-1") active_ws=1 ;;
                "DP-1") active_ws=11 ;;
                "HDMI-A-2") active_ws=21 ;;
            esac
        fi

        # Ermittle relativen Workspace
        local rel_ws=$(get_relative_workspace $active_ws $monitor_name)

        # Füge zu Display-Text hinzu (vertikal mit Newlines)
        if [ -n "$display_text" ]; then
            display_text="${display_text}\n"
        fi
        display_text="${display_text}${rel_ws}"
    done

    # Ausgabe als JSON für waybar
    echo "{\"text\":\"$display_text\"}"
}

get_all_workspaces
