#!/usr/bin/env bash
set -euo pipefail

pkg_update() {
    read -rp "Do you want to update the system? (y/n): " confirm < /dev/tty
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        log_info "Updating system..."
        sudo pacman -Syu --noconfirm
        log_info "System updated successfully."
    else
        log_warn "Update cancelled."
    fi
}

pkg_install() {
    local output_file output status
    output_file=$(mktemp)

    set +e
    sudo pacman -S --noconfirm --needed "$@" 2>&1 | tee "$output_file"
    status=${PIPESTATUS[0]}
    set -e
    output=$(<"$output_file")
    rm -f "$output_file"

    if [[ $status -ne 0 ]] && grep -qE "estão em conflito|are in conflict" <<< "$output"; then
        _resolve_pacman_conflict "$@"
        return $?
    fi

    return $status
}

_resolve_pacman_conflict() {
    local pkgs=("$@")
    local output_file output line pkg_b sep status

    output_file=$(mktemp)
    set +e
    sudo pacman -S --needed --noconfirm "${pkgs[@]}" 2>&1 | tee "$output_file"
    status=${PIPESTATUS[0]}
    set -e
    output=$(<"$output_file")
    rm -f "$output_file"

    if grep -q "estão em conflito" <<< "$output"; then
        line=$(grep -oP '^:: \K.*(?= estão em conflito)' <<< "$output" | head -1)
        sep=' e '
    else
        line=$(grep -oP '^:: \K.*(?= are in conflict)' <<< "$output" | head -1)
        sep=' and '
    fi

    if [[ -z "$line" ]]; then
        log_warn "Could not identify the conflicting package."
        return "$status"
    fi

    pkg_b=$(awk -F"$sep" '{print $2}' <<< "$line" | sed -E 's/-[0-9].*//')

    log_warn "Conflict detected: '$pkg_b' needs to be removed to continue."

    if printf 'Yes\nNo\n' | fzf --prompt="Remove $pkg_b to resolve the conflict? " | grep -q "Yes"; then
        sudo pacman -Rdd --noconfirm "$pkg_b" || { log_warn "Failed to remove $pkg_b."; return 1; }
        sudo pacman -S --needed --noconfirm "${pkgs[@]}"
        return $?
    else
        log_warn "Conflict not resolved, installation cancelled."
        return 1
    fi
}

pkg_remove() {
    sudo pacman -Rns --noconfirm "$@"
}

pkg_exists() {
    pacman -Qi "$1" &>/dev/null
}

get_desktop_packages() {
    case "$1" in
        kde)        echo "plasma-meta plasma-wayland-session" ;;
        xfce)       echo "xfce4 xfce4-goodies" ;;
        hyprland)   echo "hyprland hyprpaper xdg-desktop-portal-hyprland" ;;
        cosmic)     echo "" ;;
        gnome)      echo "gnome" ;;
        mate)       echo "mate" ;;
        cinnamon)   echo "cinnamon" ;;
        i3)         echo "i3" ;;
        sway)       echo "sway" ;;
        budgie)     echo "budgie-desktop" ;;
        *)          echo "$1" ;;
    esac
}