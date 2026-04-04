#!/usr/bin/env bash
set -euo pipefail

install_flatpak() {
    if pkg_exists flatpak; then
        log_info "Flatpak is already installed."
        return 0
    fi

    log_info "Installing Flatpak..."
    pkg_install flatpak || die "Failed to install Flatpak."
    log_info "Flatpak installed successfully."
}

configure_flatpak() {
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || die "Failed to add Flathub repository."
    log_info "Flathub repository added successfully."
}

setup_flatpak() {
    if ! pkg_exists flatpak; then
        read -rp "Flatpak is not installed. Do you want to install it now? (y/n): " confirm < /dev/tty
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            install_flatpak
        else
            log_warn "Skipping Flatpak installation."
            return 0
        fi
    else
        log_info "Flatpak is already installed."
    fi

    configure_flatpak
}