#!/usr/bin/env bash
set -euo pipefail 

install_konsole() { 
    if pkg_exists "konsole"; then
        log_info "Konsole is already installed."
        return 0
    fi

    log_info "Installing Konsole..."
    pkg_install "konsole" || die "Failed to install Konsole."
    log_info "Konsole installed successfully."
}

setup_konsole() {
    install_konsole
}
