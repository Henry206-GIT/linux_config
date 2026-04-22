# smart-wofi.sh

Startet Apps via wofi (drun-Modus) mit Jump-to-Window-Logik fuer Multi-Monitor-Setup.
Monitor-Workspace-Aufteilung: HDMI-A-1 = WS 1-10, DP-1 = WS 11-20, HDMI-A-2 = WS 21-30.
Falls ein Fenster der gewaehlten App bereits offen ist, wird auf den korrekten Monitor
und Workspace gewechselt, das Fenster fokussiert und die Maus in die Fenstermitte gewarpt.
Ausnahmen werden in jump-exclude.json definiert.

Input:
- ~/.config/hypr/jump-exclude.json (Liste ausgeschlossener App-Namen)

Output:
- Hyprland dispatch-Aktionen: workspace-Wechsel, Fensterfokus, Maus-Warp
- ~/.config/hypr/logs/smart-wofi-errors.json (Fehlerlog)
