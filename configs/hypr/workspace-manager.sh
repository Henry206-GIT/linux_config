#!/bin/bash

# #######################################################################################
# Hyprland Workspace Manager - Fixed Name-Based Version
# #######################################################################################

WORKSPACES_PER_MONITOR=10

# Funktion: Ermittelt den Offset basierend auf dem Namen des Monitors
get_workspace_offset() {
    local monitor_name=$(hyprctl activeworkspace -j | jq -r '.monitor')
    
    case "$monitor_name" in
        "HDMI-A-1")
            echo 0
            ;;
        "DP-1")
            echo 10
            ;;
        "HDMI-A-2")
            echo 20
            ;;
        *)
            # Fallback für unbekannte Monitore
            echo 0
            ;;
    esac
}

# Funktion: Zu Workspace wechseln
switch_workspace() {
    local workspace_num=$1
    local offset=$(get_workspace_offset)
    local target_workspace=$((offset + workspace_num))
    
    hyprctl dispatch workspace $target_workspace
}

# Funktion: Fenster zu Workspace verschieben (mit Fokus)
move_to_workspace() {
    local workspace_num=$1
    local offset=$(get_workspace_offset)
    local target_workspace=$((offset + workspace_num))
    
    hyprctl dispatch movetoworkspace $target_workspace
}

# Funktion: Fenster zu Workspace verschieben (ohne Fokus)
move_to_workspace_silent() {
    local workspace_num=$1
    local offset=$(get_workspace_offset)
    local target_workspace=$((offset + workspace_num))
    
    hyprctl dispatch movetoworkspacesilent $target_workspace
}

# Funktion: Workspace zyklisch innerhalb des Monitors wechseln
cycle_workspace() {
    local direction=$1  # "next" oder "prev"
    local offset=$(get_workspace_offset)
    local current_workspace=$(hyprctl activeworkspace -j | jq -r '.id')
    
    # Relativen Index berechnen (1-10)
    local relative_workspace=$((current_workspace - offset))
    
    if [ "$direction" == "next" ]; then
        relative_workspace=$((relative_workspace + 1))
        if [ $relative_workspace -gt $WORKSPACES_PER_MONITOR ]; then
            relative_workspace=1
        fi
    elif [ "$direction" == "prev" ]; then
        relative_workspace=$((relative_workspace - 1))
        if [ $relative_workspace -lt 1 ]; then
            relative_workspace=$WORKSPACES_PER_MONITOR
        fi
    fi
    
    local target_workspace=$((offset + relative_workspace))
    hyprctl dispatch workspace $target_workspace
}

# Funktion: Fenster zu nächstem/vorherigem Monitor verschieben
change_monitor() {
    local direction=$1
    if [ "$direction" == "next" ]; then
        hyprctl dispatch movecurrentworkspacetomonitor +1
    elif [ "$direction" == "prev" ]; then
        hyprctl dispatch movecurrentworkspacetomonitor -1
    fi
}

# Hauptprogramm
case "$1" in
    workspace)
        switch_workspace "$2"
        ;;
    movetoworkspace)
        move_to_workspace "$2"
        ;;
    movetoworkspacesilent)
        move_to_workspace_silent "$2"
        ;;
    cycle)
        cycle_workspace "$2"
        ;;
    changemonitor)
        change_monitor "$2"
        ;;
    *)
        echo "Usage: $0 {workspace|movetoworkspace|movetoworkspacesilent|cycle|changemonitor} [arg]"
        exit 1
        ;;
esac
