#!/usr/bin/env bash
set -euo pipefail

install_ghostty() {
    log_info "Installing Ghostty..."

    case "$DISTRO" in
        arch)
            pkg_install ghostty \
                || die "Failed to install Ghostty."
            ;;
        debian)
            log_info "Installing Ghostty via install script (ubuntu)..."
            local tmp_script
            tmp_script=$(mktemp)
            curl -fsSL "https://raw.githubusercontent.com/mkasberg/ghostty-ubuntu/HEAD/install.sh" -o "$tmp_script" \
                || die "Failed to download Ghostty installer."
            sudo bash "$tmp_script" || { rm -f "$tmp_script"; die "Failed to install Ghostty."; }
            rm -f "$tmp_script"
            ;;
        fedora)
            log_info "Enabling Ghostty COPR and installing..."
            sudo dnf copr enable -y scottames/ghostty \
                || die "Failed to enable Ghostty COPR."
            pkg_install ghostty \
                || die "Failed to install Ghostty."
            ;;
        *)
            die "Unsupported distro for Ghostty: $DISTRO"
            ;;
    esac

    log_info "Ghostty installed successfully."
}
