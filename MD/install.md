# install.sh

Stellt ein gesichertes Arch Linux Setup auf einem neuen System wieder her.
Installiert alle Pakete (pacman + AUR) und kopiert Konfigurationsdateien an die richtigen Stellen.

## Input

- `packages/pacman.txt` - Liste explizit installierter offizieller Pakete
- `packages/aur.txt` - Liste installierter AUR-Pakete
- `configs/*` - Konfigurationsordner fuer ~/.config/
- `dotfiles/.*` - Dotfiles fuer das Home-Verzeichnis

## Output

- Installierte Pakete auf dem Zielsystem
- Konfigurationen unter `~/.config/`
- Dotfiles unter `~/`
- Fehlerlog: `install.log` (JSON-Format)

## Verwendung

```bash
chmod +x install.sh
./install.sh
```

## Enthaltene Konfigurationen

- hypr (Hyprland)
- fish
- waybar
- wofi
- kitty
- alacritty
- nvim
- dunst
- btop
- neofetch

## Enthaltene Dotfiles

- .tmux.conf
- .gitconfig
- .bashrc
- .bash_profile
