# workspace-indicator.sh

## Beschreibung
Skript zur Anzeige der aktuell aktiven Workspaces aller Monitore in Waybar.

## Input
- Hyprctl workspaces JSON-Daten
- Monitor-Namen: HDMI-A-1, DP-1, HDMI-A-2

## Output
- JSON-formatierter Text für Waybar
- Format: {"text":"M1: X | M2: Y | M3: Z"}
- Wobei X, Y, Z die relativen Workspace-Nummern (1-10) pro Monitor sind
