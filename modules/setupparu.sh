#!/bin/bash
# This script is setup paru only for arch distros 
set -euo pipefail

setup_paru() {
    if command -v paru &>/dev/null; then
        log_info "paru is already installed."
        return 0
    fi

    if ! command -v git &>/dev/null; then
        log_warn "Git is not installed. paru requires Git. Please install it and try again."
        return 1
    fi

    if [[ $EUID -eq 0 ]]; then
        die "paru cannot be built as root. Please run dsxtool as a normal user."
    fi

    read -rp "Do you want to install paru? (y/n): " confirm < /dev/tty
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        log_warn "Skipping paru installation."
        return 0
    fi

    log_info "Installing base-devel (required for makepkg)..."
    sudo pacman -S --noconfirm --needed base-devel \
        || die "Failed to install base-devel."

    log_info "Installing paru..."

    local tmp_dir
    tmp_dir=$(mktemp -d)

    git clone https://aur.archlinux.org/paru.git "$tmp_dir" \
        || { rm -rf "$tmp_dir"; die "Failed to clone paru repository."; }

    (cd "$tmp_dir" && makepkg -si --noconfirm) \
        || { rm -rf "$tmp_dir"; die "Failed to build/install paru."; }

    rm -rf "$tmp_dir"
    log_info "paru installed successfully."
}


