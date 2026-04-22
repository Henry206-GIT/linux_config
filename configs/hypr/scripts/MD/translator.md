# translator.py

Kleines schwebendes GTK4-Fenster zur automatischen Uebersetzung von Deutsch nach Englisch.
Uebersetzt beim Tippen (400ms Debounce) und kopiert das Ergebnis automatisch in die Zwischenablage.

Input: Texteingabe im Fenster (Deutsch)
Output: Uebersetzung (Englisch) im Fenster + Zwischenablage

## Abhaengigkeiten

- python-gobject (GTK4) - normalerweise vorinstalliert
- wl-clipboard: `wl-copy` - normalerweise vorinstalliert
- Keine weiteren externen Python-Pakete (urllib ist stdlib)

## Starten

Tastenkuerzel: Alt+U (via Hyprland)
Oder direkt: `python3 ~/.config/hypr/scripts/translator.py`

Schliessen: Escape

## Logs

`~/.config/hypr/logs/translator.log` (JSON-Format)
