function pwd --description 'Zeigt Arbeitsverzeichnis und kopiert in Zwischenablage'
    set -l current_path (builtin pwd)
    echo $current_path

    # Für Wayland (wl-clipboard)
    if type -q wl-copy
        echo -n $current_path | wl-copy
    # Für X11 (xclip)
    else if type -q xclip
        echo -n $current_path | xclip -selection clipboard
    # Für X11 (xsel)
    else if type -q xsel
        echo -n $current_path | xsel --clipboard
    end
end
