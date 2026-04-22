// hypr-clock.cpp
// Terminal-Uhr Widget als Ersatz fuer tty-clock.
// Kompilieren ohne Flag: HH:MM — mit -DMIT_SEKUNDEN: HH:MM:SS

#include <ncurses.h>
#include <csignal>
#include <ctime>
#include <unistd.h>

// --- Globale Zustandsvariablen ---
static volatile sig_atomic_t g_groesse_geaendert = 0;
static volatile sig_atomic_t g_laeuft = 1;
static WINDOW* g_uhrfenster = nullptr;

// Ziffernmatrix: 5 Zeilen x 3 Spalten (15 Bits), gerendert als 2x1 Bloecke
const bool ZIFFERN[10][15] = {
    {1,1,1, 1,0,1, 1,0,1, 1,0,1, 1,1,1}, // 0
    {0,0,1, 0,0,1, 0,0,1, 0,0,1, 0,0,1}, // 1
    {1,1,1, 0,0,1, 1,1,1, 1,0,0, 1,1,1}, // 2
    {1,1,1, 0,0,1, 1,1,1, 0,0,1, 1,1,1}, // 3
    {1,0,1, 1,0,1, 1,1,1, 0,0,1, 0,0,1}, // 4
    {1,1,1, 1,0,0, 1,1,1, 0,0,1, 1,1,1}, // 5
    {1,1,1, 1,0,0, 1,1,1, 1,0,1, 1,1,1}, // 6
    {1,1,1, 0,0,1, 0,0,1, 0,0,1, 0,0,1}, // 7
    {1,1,1, 1,0,1, 1,1,1, 1,0,1, 1,1,1}, // 8
    {1,1,1, 1,0,1, 1,1,1, 0,0,1, 1,1,1}, // 9
};

// Layout-Konstanten
const int NORMBREITE = 35; // HH:MM
const int SEKBREITE  = 54; // HH:MM:SS
const int FRAMEH     = 7;

// Signal-Handler: setzt g_groesse_geaendert bei SIGWINCH, g_laeuft=0 bei SIGINT/SIGTERM
// Input: Signalnummer | Output: keine
void signal_handler(int sig) {
    if (sig == SIGWINCH) {
        g_groesse_geaendert = 1;
    } else {
        g_laeuft = 0;
    }
}

// Initialisiert ncurses, Farben, Fenster und Signal-Handler
// Input: mit_sekunden (bool) | Output: keine
void initialisieren(bool mit_sekunden) {
    initscr();
    cbreak();
    noecho();
    curs_set(0);
    keypad(stdscr, TRUE);
    nodelay(stdscr, TRUE);

    start_color();
    use_default_colors();
    // Farbpaar 1: aktives Segment (gruener Block)
    init_pair(1, COLOR_GREEN, COLOR_GREEN);
    // Farbpaar 2: inaktives Segment (Terminal-Standardhintergrund)
    init_pair(2, -1, -1);

    int breite = mit_sekunden ? SEKBREITE : NORMBREITE;
    int max_y, max_x;
    getmaxyx(stdscr, max_y, max_x);
    int start_y = (max_y - FRAMEH) / 2;
    int start_x = (max_x - breite) / 2;

    g_uhrfenster = newwin(FRAMEH, breite, start_y, start_x);

    signal(SIGWINCH, signal_handler);
    signal(SIGINT,   signal_handler);
    signal(SIGTERM,  signal_handler);
}

// Berechnet zentrierte Startposition fuer x oder y
// Input: gesamt (Terminalgroesse), element (Elementgroesse) | Output: Startposition
int mitte_berechnen(int gesamt, int element) {
    return (gesamt - element) / 2;
}

// Liest aktuelle Systemzeit und befuellt Ziffernarray
// Input: Zeiger auf stunden[], minuten[], sekunden[] (je 2 int) | Output: keine
void zeit_lesen(int* stunden, int* minuten, int* sekunden) {
    time_t jetzt = time(nullptr);
    struct tm* t = localtime(&jetzt);
    stunden[0] = t->tm_hour / 10;
    stunden[1] = t->tm_hour % 10;
    minuten[0] = t->tm_min  / 10;
    minuten[1] = t->tm_min  % 10;
    sekunden[0] = t->tm_sec / 10;
    sekunden[1] = t->tm_sec % 10;
}

// Zeichnet eine Block-Ziffer an der angegebenen Position (2x1 Bloecke)
// Input: n (Ziffer 0-9), start_zeile, start_spalte | Output: keine
void ziffer_zeichnen(int n, int start_zeile, int start_spalte) {
    for (int i = 0; i < 30; ++i) {
        int spalte = start_spalte + (i % 6);
        int zeile  = start_zeile  + (i / 6);
        int pair   = ZIFFERN[n][i / 2] ? 1 : 2;
        wattron(g_uhrfenster, COLOR_PAIR(pair));
        mvwaddch(g_uhrfenster, zeile, spalte, ' ');
        wattroff(g_uhrfenster, COLOR_PAIR(pair));
    }
}

// Zeichnet einen Doppelpunkt-Trenner an gegebener Spalte
// Input: spalte | Output: keine
void doppelpunkt_zeichnen(int spalte) {
    wattron(g_uhrfenster, COLOR_PAIR(1));
    mvwaddch(g_uhrfenster, 2, spalte,     ' ');
    mvwaddch(g_uhrfenster, 2, spalte + 1, ' ');
    mvwaddch(g_uhrfenster, 4, spalte,     ' ');
    mvwaddch(g_uhrfenster, 4, spalte + 1, ' ');
    wattroff(g_uhrfenster, COLOR_PAIR(1));
}

// Zeichnet die komplette Uhr (alle Ziffern und Trenner) und aktualisiert das Fenster
// Input: stunden[], minuten[], sekunden[], mit_sekunden | Output: keine
void uhr_zeichnen(int* stunden, int* minuten, int* sekunden, bool mit_sekunden) {
    wbkgd(g_uhrfenster, COLOR_PAIR(2) | ' ');
    werase(g_uhrfenster);

    ziffer_zeichnen(stunden[0], 1,  1);
    ziffer_zeichnen(stunden[1], 1,  8);
    doppelpunkt_zeichnen(16);
    ziffer_zeichnen(minuten[0], 1, 20);
    ziffer_zeichnen(minuten[1], 1, 27);

    if (mit_sekunden) {
        doppelpunkt_zeichnen(35);
        ziffer_zeichnen(sekunden[0], 1, 39);
        ziffer_zeichnen(sekunden[1], 1, 46);
    }

    wrefresh(g_uhrfenster);
}

// Zentriert das Uhren-Fenster nach einem Terminal-Resize (SIGWINCH)
// Input: mit_sekunden | Output: keine
void fenster_zentrieren(bool mit_sekunden) {
    int max_y, max_x;
    getmaxyx(stdscr, max_y, max_x);
    int breite = mit_sekunden ? SEKBREITE : NORMBREITE;
    int start_y = mitte_berechnen(max_y, FRAMEH);
    int start_x = mitte_berechnen(max_x, breite);
    wresize(g_uhrfenster, FRAMEH, breite);
    mvwin(g_uhrfenster, start_y, start_x);
}

// Gibt alle ncurses-Ressourcen frei
// Input: keine | Output: keine
void aufraeumen() {
    if (g_uhrfenster) {
        delwin(g_uhrfenster);
        g_uhrfenster = nullptr;
    }
    endwin();
}

int main() {
#ifdef MIT_SEKUNDEN
    constexpr bool mit_sekunden = true;
#else
    constexpr bool mit_sekunden = false;
#endif

    initialisieren(mit_sekunden);

    int stunden[2], minuten[2], sekunden[2];

    while (g_laeuft) {
        if (g_groesse_geaendert) {
            g_groesse_geaendert = 0;
            endwin();
            refresh();
            wclear(stdscr);
            fenster_zentrieren(mit_sekunden);
        }

        zeit_lesen(stunden, minuten, sekunden);
        uhr_zeichnen(stunden, minuten, sekunden, mit_sekunden);

        struct timespec ts = {0, 500000000L};
        nanosleep(&ts, nullptr);
    }

    aufraeumen();
    return 0;
}
