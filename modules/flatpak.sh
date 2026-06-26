#!/usr/bin/env bash
set -euo pipefail

_install_flatpak() {
    log_info "Installing Flatpak..."
    pkg_install flatpak || die "Failed to install Flatpak."
    log_info "Flatpak installed successfully."
}

_configure_flatpak() {
    log_info "Adding Flathub repository..."
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo \
        || die "Failed to add Flathub repository."
    log_info "Flathub repository added successfully."
}

setup_flatpak() {
    if pkg_exists flatpak; then
        log_info "Flatpak is already installed."
    else
        read -rp "Flatpak is not installed. Do you want to install it now? (y/n): " confirm < /dev/tty
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            _install_flatpak
        else
            log_warn "Skipping Flatpak installation."
            return 0
        fi
    fi

    _configure_flatpak
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    setup_flatpak "$@"
fi