#!/usr/bin/env bash
set -euo pipefail


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
        kde) echo "kde-plasma-desktop" ;;
        xfce) echo "xfce4" ;;
        hyprland) echo "hyprland" ;;
        *) echo "$1" ;;
    esac
}