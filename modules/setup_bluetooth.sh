#!/usr/bin/env bash
set -euo pipefail

install_bluetooth() {
    if command -v bluetoothctl &>/dev/null; then
        log_info "Bluetooth (bluez) is already installed."
        return 0
    fi

    log_info "Installing Bluetooth packages..."

    case "$DISTRO" in
        arch)   pkg_install bluez bluez-utils ;;
        debian) pkg_install bluez bluez-utils ;;
        fedora) pkg_install bluez bluez-utils ;;
        *)      die "Unsupported distro for Bluetooth setup: $DISTRO" ;;
    esac

    log_info "Bluetooth packages installed successfully."
}

_bluetooth_service() {
    sudo systemctl enable --now bluetooth \
        && log_info "Bluetooth service enabled and started." \
        || log_warn "Failed to enable Bluetooth service."
}

_bluetooth_gui() {
    log_info "Installing Bluetooth GUI (blueman)..."

    case "$DISTRO" in
        arch)   pkg_install blueman ;;
        debian) pkg_install blueman ;;
        fedora) pkg_install blueman ;;
        *)      log_warn "Unsupported distro for blueman." ;;
    esac

    log_info "blueman installed successfully."
}

setup_bluetooth() {
    install_bluetooth
    _bluetooth_service

    read -rp "Install blueman (GUI for Bluetooth)? (y/n): " confirm < /dev/tty
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        _bluetooth_gui
    else
        log_warn "Skipping blueman installation."
    fi
}