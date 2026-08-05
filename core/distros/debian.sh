#!/usr/bin/env bash


pkg_update() {
    read -rp "Do you want to update the system? (y/n): " confirm < /dev/tty
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        log_info "Updating system..."
        sudo apt update -y && sudo apt upgrade -y
        log_info "System updated successfully."
    else
        log_warn "Update cancelled."
    fi
}

pkg_install() {
    sudo apt install -y "$@"
}

pkg_remove() {
    sudo apt remove -y "$@"
}

pkg_exists() {
    dpkg -s "$1" &>/dev/null
}

# Desktop environment package mappings
get_desktop_packages() {
    case "$1" in
        kde)        echo "kde-plasma-desktop" ;;
        xfce)       echo "xfce4 xfce4-goodies" ;;
        hyprland)   echo "hyprland hyprpaper" ;;
        cosmic)     echo "cosmic-desktop" ;;
        gnome)      echo "gnome" ;;
        mate)       echo "mate-desktop-environment" ;;
        cinnamon)   echo "cinnamon-desktop" ;;
        i3)         echo "i3" ;;
        sway)       echo "sway" ;;
        budgie)     echo "budgie-desktop" ;;
        *)          echo "$1" ;;
    esac
}
