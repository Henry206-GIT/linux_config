#!/usr/bin/env python3
# Uebersetzer-Tool: Kleines schwebendes Fenster fuer Deutsch-nach-Englisch Uebersetzungen.
# Startet via Alt+U, uebersetzt automatisch beim Tippen, kopiert Ergebnis in Zwischenablage.

import gi
gi.require_version('Gtk', '4.0')
from gi.repository import Gtk, GLib
import subprocess
import threading
import json
import traceback
import urllib.request
import urllib.parse
from datetime import datetime
from pathlib import Path

LOG_DIR = Path.home() / ".config/hypr/logs"
LOG_DIR.mkdir(parents=True, exist_ok=True)
LOG_FILE = LOG_DIR / "translator.log"

debounce_id = None


# Schreibt Fehler im strukturierten JSON-Format in die Log-Datei.
# Input: funktionsname (str), fehler (Exception), variablen (dict optional)
# Output: None
def log_fehler(funktionsname, fehler, variablen=None):
    eintrag = {
        "zeitstempel": datetime.now().isoformat(),
        "funktion": funktionsname,
        "fehlertyp": type(fehler).__name__,
        "nachricht": str(fehler),
        "stacktrace": traceback.format_exc(),
        "variablen": variablen or {}
    }
    try:
        with open(LOG_FILE, "a") as f:
            f.write(json.dumps(eintrag, ensure_ascii=False) + "\n")
    except Exception:
        pass


# Sendet Text an die inoffizielle Google Translate API und gibt Uebersetzung zurueck.
# Input: text (str) - Quelltext auf Deutsch
# Output: uebersetzung (str) oder None bei Fehler
def google_uebersetzen(text):
    url = (
        "https://translate.googleapis.com/translate_a/single"
        "?client=gtx&sl=de&tl=en&dt=t&q=" + urllib.parse.quote(text)
    )
    anfrage = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(anfrage, timeout=5) as antwort:
        daten = json.loads(antwort.read().decode("utf-8"))
    teile = [segment[0] for segment in daten[0] if segment[0]]
    return "".join(teile)


# Fuehrt Uebersetzung im Hintergrund-Thread aus, aktualisiert UI thread-sicher.
# Input: text (str), ausgabe_label (Gtk.Label)
# Output: None
def uebersetzen_thread(text, ausgabe_label):
    try:
        if not text.strip():
            GLib.idle_add(ausgabe_label.set_text, "")
            return

        uebersetzung = google_uebersetzen(text)

        def ui_aktualisieren():
            ausgabe_label.set_text(uebersetzung)
            try:
                subprocess.run(["wl-copy", uebersetzung], check=True)
            except Exception as e:
                log_fehler("ui_aktualisieren.wl_copy", e, {"uebersetzung": uebersetzung})
            return False

        GLib.idle_add(ui_aktualisieren)

    except Exception as e:
        log_fehler("uebersetzen_thread", e, {"text": text})
        GLib.idle_add(ausgabe_label.set_text, "[Fehler bei Uebersetzung]")


# Wird bei jeder Texteingabe aufgerufen; startet Uebersetzung nach 400ms Debounce.
# Input: eingabe_widget (Gtk.Entry), ausgabe_label (Gtk.Label)
# Output: None
def bei_texteingabe(eingabe_widget, ausgabe_label):
    global debounce_id

    if debounce_id is not None:
        GLib.source_remove(debounce_id)

    text = eingabe_widget.get_text()

    def starte_thread():
        t = threading.Thread(target=uebersetzen_thread, args=(text, ausgabe_label), daemon=True)
        t.start()
        return False

    debounce_id = GLib.timeout_add(400, starte_thread)


# Erstellt und zeigt das Hauptfenster mit Eingabefeld und Uebersetzungs-Label.
# Input: app (Gtk.Application)
# Output: None
def fenster_erstellen(app):
    try:
        fenster = Gtk.ApplicationWindow(application=app)
        fenster.set_title("Uebersetzer")
        fenster.set_default_size(360, 110)
        fenster.set_resizable(False)

        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
        box.set_margin_top(10)
        box.set_margin_bottom(10)
        box.set_margin_start(10)
        box.set_margin_end(10)

        eingabe = Gtk.Entry()
        eingabe.set_placeholder_text("Deutsch...")

        ausgabe = Gtk.Label(label="")
        ausgabe.set_xalign(0)
        ausgabe.set_wrap(True)
        ausgabe.set_selectable(True)

        eingabe.connect("changed", bei_texteingabe, ausgabe)

        # Escape schliesst das Fenster
        key_ctrl = Gtk.EventControllerKey()
        key_ctrl.connect(
            "key-pressed",
            lambda ctrl, keyval, keycode, mod: fenster.close() if keyval == 65307 else None
        )
        fenster.add_controller(key_ctrl)

        box.append(eingabe)
        box.append(ausgabe)
        fenster.set_child(box)
        fenster.present()
        eingabe.grab_focus()

    except Exception as e:
        log_fehler("fenster_erstellen", e, {})


# Einstiegspunkt: Initialisiert GTK-Anwendung.
# Input: keine
# Output: keine
def main():
    app = Gtk.Application(application_id="translator-float")
    app.connect("activate", fenster_erstellen)
    app.run(None)


if __name__ == "__main__":
    main()
