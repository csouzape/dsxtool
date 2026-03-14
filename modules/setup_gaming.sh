#!/usr/bin/env bash
set -uo pipefail



_enable_multilib_arch() {
    if grep -q "^\s*\[multilib\]" /etc/pacman.conf; then
        log_info "multilib is already enabled."
        return 0
    fi

    log_info "Enabling multilib repository..."
    echo -e "\n[multilib]\nInclude = /etc/pacman.d/mirrorlist" | sudo tee -a /etc/pacman.conf > /dev/null
    sudo pacman -Syu --noconfirm || die "Failed to sync after enabling multilib."
    log_info "multilib enabled."
}

_install_gaming_arch() {
    _enable_multilib_arch

    local deps=(
        wine dbus git
        gnutls lib32-gnutls
        gtk3 lib32-gtk3
        libpulse lib32-libpulse
        alsa-lib lib32-alsa-lib alsa-utils alsa-plugins lib32-alsa-plugins
        giflib lib32-giflib
        libpng lib32-libpng
        libldap lib32-libldap
        openal lib32-openal
        libxcomposite lib32-libxcomposite
        libxinerama lib32-libxinerama
        libgcrypt lib32-libgcrypt
        libgpg-error lib32-libgpg-error
        ncurses lib32-ncurses
        mpg123 lib32-mpg123
        libjpeg-turbo lib32-libjpeg-turbo
        sqlite lib32-sqlite
        libva lib32-libva
        gst-plugins-base-libs lib32-gst-plugins-base-libs
        sdl2 lib32-sdl2
        v4l-utils lib32-v4l-utils
        vulkan-icd-loader lib32-vulkan-icd-loader
        ocl-icd lib32-ocl-icd
        libxslt lib32-libxslt
        cups lib32-mesa
        vulkan-radeon lib32-vulkan-radeon
        mangohud lib32-mangohud
        gamemode lib32-gamemode
        steam lutris
    )

    log_info "Installing gaming dependencies for Arch..."
    pkg_install "${deps[@]}" || die "Failed to install gaming dependencies."
}

_install_gaming_debian() {
    log_info "Adding i386 architecture..."
    sudo dpkg --add-architecture i386
    sudo apt-get update -y

    local deps=(
        wine dbus git
        libasound2-plugins:i386
        libsdl2-2.0-0:i386
        libdbus-1-3:i386
        libsqlite3-0:i386
        wine32:i386
        steam
    )

    log_info "Installing gaming dependencies for Debian/Ubuntu..."
    pkg_install "${deps[@]}" || die "Failed to install gaming dependencies."

    
    log_info "Installing Lutris from GitHub releases..."
    local lutris_url
    lutris_url=$(curl -s https://api.github.com/repos/lutris/lutris/releases/latest \
        | grep "browser_download_url.*\.deb" \
        | cut -d '"' -f 4)

    if [[ -n "$lutris_url" ]]; then
        curl -sSLo /tmp/lutris.deb "$lutris_url" \
            || die "Failed to download Lutris."
        sudo dpkg -i /tmp/lutris.deb || sudo apt-get install -f -y
        rm -f /tmp/lutris.deb
        log_info "Lutris installed."
    else
        log_warn "Could not fetch Lutris release URL. Trying apt..."
        pkg_install lutris || log_warn "Lutris not available in apt."
    fi
}

_install_gaming_fedora() {
    log_info "Adding RPM Fusion repositories..."
    local fedora_ver
    fedora_ver=$(rpm -E %fedora)

    sudo dnf install -y \
        "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${fedora_ver}.noarch.rpm" \
        "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${fedora_ver}.noarch.rpm" \
        || die "Failed to add RPM Fusion repos."

    sudo dnf config-manager setopt --repo fedora-cisco-openh264 enabled=1 2>/dev/null || true

    local deps=(wine dbus git steam lutris)

    log_info "Installing gaming dependencies for Fedora..."
    pkg_install "${deps[@]}" || die "Failed to install gaming dependencies."
}

setup_gaming() {
    log_info "Setting up gaming environment..."
    log_warn "This will install Wine, Steam, Lutris and gaming libraries."
    log_warn "On Arch, multilib will be enabled if not already."
    echo ""

    read -rp "Continue? (y/n): " confirm < /dev/tty
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        log_warn "Gaming setup cancelled."
        return 0
    fi

    case "$DISTRO" in
        arch)   _install_gaming_arch ;;
        debian) _install_gaming_debian ;;
        fedora) _install_gaming_fedora ;;
        *)      die "Unsupported distro for gaming setup: $DISTRO" ;;
    esac

    log_info "Gaming setup completed successfully."
    log_info "Tip: run 'gamemoded -t' to test GameMode, and 'mangohud <game>' to enable the overlay."
}