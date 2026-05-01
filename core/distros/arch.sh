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
    sudo pacman -S --noconfirm --needed "$@"
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