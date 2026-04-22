if status is-interactive
    # Commands to run in interactive sessions can go here
    alias v='nvim'
    alias clock='kitty --class clock-float --override font_size=8 /home/henry/.config/hypr/CPP_Widget/clock'
    alias clock-sec='kitty --class clock-float --override font_size=8 /home/henry/.config/hypr/CPP_Widget/clock-sec'
    alias fcon='v ~/.config/fish/config.fish'
    alias scr='cd /home/henry/Vault/Scrapper'
    alias dock='cd /home/henry/dock'
    alias c='clear'

    # Tmux-Statusleiste ein-/ausschalten
    function bar
        set status_state (tmux show-option -gv status)
        if test "$status_state" = "on"
            tmux set-option -g status off
        else
            tmux set-option -g status on
        end
    end

    # Kopiere absoluten Pfad in Zwischenablage
    function cpf
        realpath $argv[1] | wl-copy
    end
end
# Fish-Begrüßung deaktivieren
set -g fish_greeting ""
# IME deaktivieren (verhindert Lag in Alacritty + Neovim)
set -gx XMODIFIERS @im=none
set -gx GTK_IM_MODULE ""
set -gx QT_IM_MODULE ""

# Cargo/Rust zu PATH hinzufügen
fish_add_path $HOME/.cargo/bin

# Created by `pipx` on 2025-10-15 12:42:54
set PATH $PATH /home/henry/.local/bin
set -gx PYENV_ROOT $HOME/.pyenv
set -gx PATH $PYENV_ROOT/bin $PATH
status is-interactive; and pyenv init - | source

set -gx PYENV_ROOT $HOME/.pyenv
set -gx PATH $PYENV_ROOT/bin $PATH
status is-interactive; and pyenv init - | source

# CUDA Environment Variables
set -gx PATH /opt/cuda/bin $PATH
set -gx LD_LIBRARY_PATH /opt/cuda/lib64 $LD_LIBRARY_PATH

# DevContext TursoDB Credentials
set -gx TURSO_DATABASE_URL "libsql://mein-projekt-devcontext-xyz.turso.io"
set -gx TURSO_AUTH_TOKEN "eyJhbGciOiJFZERTQSIsInR5cCI6IkpXVCJ9.eyJpYXQiOjE3NjQ5MjgwNDYsImlkIjoiZjQzZGFmMzUtZWNkNC00ZmU0LWIxNjUtMDhmZTQ2MmRkZjE0IiwicmlkIjoiZmE1ZjA0ZjctZDc4Ny00NjBiLTg5ZWMtOWNkODU3MmI4NmFmIn0.CiMhYhgjLH9ZJ3nS3hiTc3ekYci0BI8EgRusd6exhzJUIoGT4ZY310zkU0T5m_FaDo_znuoxba6ecy782ljiBw"

# opencode
fish_add_path /home/henry/.opencode/bin
