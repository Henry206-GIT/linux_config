#!/usr/bin/env bash
# install.sh - Arch Linux Setup: Pakete installieren und Konfigurationen wiederherstellen

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/install.log"
CONFIGS_DIR="$SCRIPT_DIR/configs"
DOTFILES_DIR="$SCRIPT_DIR/dotfiles"
PACKAGES_DIR="$SCRIPT_DIR/packages"

# Fehler als JSON-Zeile in install.log schreiben
# Input: Funktionsname, Fehlertyp, Nachricht, Variablenname, Variablenwert
# Output: JSON-Eintrag in $LOG_FILE
log_error() {
    local func="$1"
    local error_type="$2"
    local message="$3"
    local var_name="${4:-}"
    local var_value="${5:-}"
    local timestamp
    timestamp=$(date -Iseconds)

    printf '{"timestamp":"%s","function":"%s","error_type":"%s","message":"%s","variable":{"name":"%s","value":"%s"}}\n' \
        "$timestamp" "$func" "$error_type" "$message" "$var_name" "$var_value" >> "$LOG_FILE"

    echo "[FEHLER] $func: $message" >&2
}

# multilib-Repository in /etc/pacman.conf aktivieren fuer Steam und 32-Bit-Pakete
# Input: /etc/pacman.conf
# Output: multilib aktiviert, Paketdatenbank aktualisiert
enable_multilib() {
    if grep -q "^\[multilib\]" /etc/pacman.conf; then
        echo "[OK] multilib bereits aktiv"
        return 0
    fi

    sudo sed -i '/^#\[multilib\]/{s/^#//;n;s/^#//}' /etc/pacman.conf

    if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
        log_error "enable_multilib" "ConfigError" "multilib konnte nicht aktiviert werden" "pacman.conf" "/etc/pacman.conf"
        return 1
    fi

    sudo pacman -Sy --noconfirm
    echo "[OK] multilib aktiviert"
}

# Pruefen ob das System Arch Linux ist
# Input: /etc/os-release
# Output: Exit 1 wenn kein Arch Linux erkannt
check_arch() {
    if ! grep -q "ID=arch" /etc/os-release 2>/dev/null; then
        log_error "check_arch" "OsError" "Kein Arch Linux erkannt" "os-release" "$(head -3 /etc/os-release 2>/dev/null)"
        exit 1
    fi
    echo "[OK] Arch Linux erkannt"
}

# yay AUR-Helper installieren falls nicht vorhanden
# Input: -
# Output: yay Binary unter /usr/bin/yay
install_yay() {
    if command -v yay &>/dev/null; then
        echo "[OK] yay bereits installiert ($(yay --version | head -1))"
        return 0
    fi

    echo "[...] yay wird installiert..."

    if ! sudo pacman -S --needed --noconfirm git base-devel; then
        log_error "install_yay" "PackageError" "base-devel/git konnte nicht installiert werden" "" ""
        exit 1
    fi

    local tmp_dir
    tmp_dir=$(mktemp -d)

    if ! git clone https://aur.archlinux.org/yay.git "$tmp_dir/yay"; then
        log_error "install_yay" "GitError" "yay Repository klonen fehlgeschlagen" "tmp_dir" "$tmp_dir"
        rm -rf "$tmp_dir"
        exit 1
    fi

    cd "$tmp_dir/yay"
    if ! makepkg -si --noconfirm; then
        log_error "install_yay" "BuildError" "yay Build fehlgeschlagen" "build_dir" "$tmp_dir/yay"
        cd "$SCRIPT_DIR"
        rm -rf "$tmp_dir"
        exit 1
    fi

    cd "$SCRIPT_DIR"
    rm -rf "$tmp_dir"
    echo "[OK] yay installiert"
}

# Offizielle Pakete aus pacman.txt installieren
# Input: packages/pacman.txt
# Output: installierte Pakete via pacman
install_pacman_packages() {
    local pkg_file="$PACKAGES_DIR/pacman.txt"

    if [[ ! -f "$pkg_file" ]]; then
        log_error "install_pacman_packages" "FileNotFound" "Paketliste nicht gefunden" "pkg_file" "$pkg_file"
        exit 1
    fi

    local count failed=0
    count=$(wc -l < "$pkg_file")
    echo "[...] $count offizielle Pakete werden installiert..."

    sudo pacman -Sy --noconfirm

    while IFS= read -r pkg; do
        [[ -z "$pkg" ]] && continue
        if ! sudo pacman -S --needed --noconfirm "$pkg" 2>/dev/null; then
            log_error "install_pacman_packages" "PackageNotFound" "Paket nicht installierbar" "pkg" "$pkg"
            ((failed++)) || true
        fi
    done < "$pkg_file"

    echo "[OK] Offizielle Pakete installiert ($failed fehlgeschlagen)"
}

# AUR-Pakete aus aur.txt installieren
# Input: packages/aur.txt
# Output: installierte Pakete via yay
install_aur_packages() {
    local pkg_file="$PACKAGES_DIR/aur.txt"

    if [[ ! -f "$pkg_file" ]]; then
        log_error "install_aur_packages" "FileNotFound" "AUR-Paketliste nicht gefunden" "pkg_file" "$pkg_file"
        exit 1
    fi

    local count
    count=$(wc -l < "$pkg_file")
    echo "[...] $count AUR-Pakete werden installiert..."

    local failed=0

    while IFS= read -r pkg; do
        [[ -z "$pkg" ]] && continue
        if ! yay -S --needed --noconfirm --nocleanmenu --nodiffmenu --removemake "$pkg" 2>/dev/null; then
            log_error "install_aur_packages" "AurError" "AUR-Paket nicht installierbar" "pkg" "$pkg"
            ((failed++)) || true
        fi
    done < "$pkg_file"

    echo "[OK] AUR-Pakete installiert ($failed fehlgeschlagen)"
}

# Konfigurationsordner nach ~/.config/ kopieren
# Input: configs/*
# Output: ~/.config/* (vorhandene Dateien werden ueberschrieben)
copy_configs() {
    local target_base="$HOME/.config"

    for config_dir in "$CONFIGS_DIR"/*/; do
        local dir_name
        dir_name=$(basename "$config_dir")
        local target="$target_base/$dir_name"

        mkdir -p "$target"

        if ! cp -r "$config_dir"* "$target/" 2>/dev/null; then
            log_error "copy_configs" "CopyError" "Konfiguration konnte nicht kopiert werden" "dir_name" "$dir_name"
        else
            echo "[OK] ~/.config/$dir_name"
        fi
    done
}

# Dotfiles ins Home-Verzeichnis kopieren
# Input: dotfiles/.*
# Output: ~/<dateiname> (vorhandene Dateien werden ueberschrieben)
copy_dotfiles() {
    local copied=0

    for dotfile in "$DOTFILES_DIR"/.*; do
        local file_name
        file_name=$(basename "$dotfile")

        [[ "$file_name" == "." || "$file_name" == ".." ]] && continue

        if ! cp "$dotfile" "$HOME/$file_name"; then
            log_error "copy_dotfiles" "CopyError" "Dotfile konnte nicht kopiert werden" "file_name" "$file_name"
        else
            echo "[OK] ~/$file_name"
            ((copied++))
        fi
    done

    echo "[OK] $copied Dotfiles kopiert"
}

echo "==============================="
echo " Arch Linux Setup"
echo "==============================="
echo "Log: $LOG_FILE"
echo ""

check_arch
enable_multilib
install_yay
install_pacman_packages
install_aur_packages
copy_configs
copy_dotfiles

echo ""
echo "==============================="
echo " Setup abgeschlossen"
echo "==============================="
