#!/usr/bin/env bash
set -euo pipefail

install_kitty() {
    if pkg_exists "kitty"; then
        log_info "Kitty is already installed."
        return 0
    fi

    log_info "Installing Kitty..."
    pkg_install "kitty" || die "Failed to install Kitty."
    log_info "Kitty installed successfully."
}

setup_kitty() {
    install_kitty
}

