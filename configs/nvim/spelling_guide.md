# ltex-ls Rechtschreibprüfung - Anleitung

## Wie man Korrekturvorschläge sieht:

### Methode 1: Code Actions (BESTE METHODE)
1. Bewege den Cursor auf das falsch geschriebene Wort
2. Drücke `<leader>ca` (normalerweise `Space` + `c` + `a`)
3. Wähle aus dem Menü die richtige Schreibweise

### Methode 2: Diagnostic Float
1. Bewege den Cursor auf das fehlerhafte Wort
2. Drücke `<leader>g`
3. Sieh die Fehlerbeschreibung

### Methode 3: Hover
1. Bewege den Cursor auf das Wort
2. Drücke `K`
3. Sieh Details zum Fehler

## Navigation:
- `]d` - Zum nächsten Fehler springen
- `[d` - Zum vorherigen Fehler springen

## Test es hier:
Dieses ist ein Testdokumnt mit mehrerem Fehlern. Die Rechtschrebung ist falsh.
