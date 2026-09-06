#!/usr/bin/env bash
set -euo pipefail

setup_yay() {
    if command -v yay &>/dev/null; then
        log_info "yay is already installed."
        return 0
    fi

    if ! command -v git &>/dev/null; then
        log_warn "Git is not installed. yay requires Git. Please install it and try again."
        return 1
    fi

    if [[ $EUID -eq 0 ]]; then
        die "yay cannot be built as root. Please run dsxtool as a normal user."
    fi

    read -rp "Do you want to install yay? (y/n): " confirm < /dev/tty
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        log_warn "Skipping yay installation."
        return 0
    fi

    log_info "Installing base-devel (required for makepkg)..."
    sudo pacman -S --noconfirm --needed base-devel \
        || die "Failed to install base-devel."

    log_info "Installing yay..."

    local tmp_dir
    tmp_dir=$(mktemp -d)

    git clone https://aur.archlinux.org/yay.git "$tmp_dir" \
        || { rm -rf "$tmp_dir"; die "Failed to clone yay repository."; }

    (cd "$tmp_dir" && makepkg -si --noconfirm) \
        || { rm -rf "$tmp_dir"; die "Failed to build/install yay."; }

    rm -rf "$tmp_dir"
    if ! command -v yay &>/dev/null; then
        die "yay build completed, but the yay command is not available."
    fi

    log_success "yay installed successfully."
}