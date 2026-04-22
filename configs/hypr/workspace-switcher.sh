#!/bin/bash

# Hyprland Workspace Manager - Ersatz für split-monitor-workspaces Plugin
# Jeder Monitor bekommt seine eigenen Workspaces (1-10 pro Monitor)

WORKSPACES_PER_MONITOR=10

get_monitor_id() {
    hyprctl activeworkspace -j | jq -r '.monitorID'
}

get_workspace_offset() {
    local monitor_id=$1
    echo $((monitor_id * WORKSPACES_PER_MONITOR))
}

# Funktion: Zu Workspace wechseln
switch_workspace() {
    local workspace_num=$1
    local monitor_id=$(get_monitor_id)
    local offset=$(get_workspace_offset $monitor_id)
    local target_workspace=$((offset + workspace_num))
    
    hyprctl dispatch workspace $target_workspace
}

# Funktion: Fenster zu Workspace verschieben (mit Fokus)
move_to_workspace() {
    local workspace_num=$1
    local monitor_id=$(get_monitor_id)
    local offset=$(get_workspace_offset $monitor_id)
    local target_workspace=$((offset + workspace_num))
    
    hyprctl dispatch movetoworkspace $target_workspace
}

# Funktion: Fenster zu Workspace verschieben (ohne Fokus)
move_to_workspace_silent() {
    local workspace_num=$1
    local monitor_id=$(get_monitor_id)
    local offset=$(get_workspace_offset $monitor_id)
    local target_workspace=$((offset + workspace_num))
    
    hyprctl dispatch movetoworkspacesilent $target_workspace
}

# Funktion: Workspace zyklisch wechseln
cycle_workspace() {
    local direction=$1  # "next" oder "prev"
    local monitor_id=$(get_monitor_id)
    local offset=$(get_workspace_offset $monitor_id)
    local current_workspace=$(hyprctl activeworkspace -j | jq -r '.id')
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
    local direction=$1  # "next" oder "prev"
    
    if [ "$direction" == "next" ]; then
        hyprctl dispatch movecurrentworkspacetomonitor +1
    elif [ "$direction" == "prev" ]; then
        hyprctl dispatch movecurrentworkspacetomonitor -1
    fi
}

# Funktion: Verlorene Fenster nach Monitor-Trennung zurückholen
grab_rogue_windows() {
    local monitor_id=$(get_monitor_id)
    local offset=$(get_workspace_offset $monitor_id)
    
    # Alle Fenster aus nicht-existierenden Workspaces zum aktuellen Monitor holen
    for i in $(seq 1 $WORKSPACES_PER_MONITOR); do
        local target_workspace=$((offset + i))
        hyprctl dispatch moveworkspacetomonitor $target_workspace current
    done
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
    grabrogue)
        grab_rogue_windows
        ;;
    *)
        echo "Usage: $0 {workspace|movetoworkspace|movetoworkspacesilent|cycle|changemonitor|grabrogue} [argument]"
        echo ""
        echo "Examples:"
        echo "  $0 workspace 1              # Wechsel zu Workspace 1 auf aktuellem Monitor"
        echo "  $0 movetoworkspace 3        # Verschiebe Fenster zu Workspace 3 (mit Fokus)"
        echo "  $0 movetoworkspacesilent 5  # Verschiebe Fenster zu Workspace 5 (ohne Fokus)"
        echo "  $0 cycle next               # Nächster Workspace (mit Wraparound)"
        echo "  $0 cycle prev               # Vorheriger Workspace (mit Wraparound)"
        echo "  $0 changemonitor next       # Fenster zum nächsten Monitor"
        echo "  $0 grabrogue                # Verlorene Fenster zurückholen"
        exit 1
        ;;
esac
