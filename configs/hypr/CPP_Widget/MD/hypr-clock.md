---
Eingabe: keine (liest Systemzeit via localtime)
Ausgabe: /home/henry/.config/hypr/CPP_Widget/clock
         /home/henry/.config/hypr/CPP_Widget/clock-sec
---

Terminale Uhr als Ersatz fuer tty-clock. Zeigt die Uhrzeit in Block-Ziffern (tty-clock-kompatibles Layout) zentriert im Terminal an.

- clock: HH:MM (ohne Sekunden)
- clock-sec: HH:MM:SS (mit Sekunden)

Beide Binaries entstehen aus derselben Quelldatei hypr-clock.cpp. clock-sec wird mit dem Flag -DMIT_SEKUNDEN kompiliert.

Unterstuetzt SIGWINCH: Bei Terminal-Resize zentriert sich die Uhr automatisch neu.
