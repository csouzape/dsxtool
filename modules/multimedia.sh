#!/usr/bin/env bash
# This script is install multimedia codecs for all distros
set -euo pipefail
source "$BASE_DIR/core/common.sh"
source "$BASE_DIR/core/detect.sh"
detect_distro

install_vainfo(){
    if pkg_exists vainfo; then
        log_info "vainfo is already installed."
        return 0
    fi
    log_info "Installing vainfo..."
    pkg_install libva-utils || die "Failed to install vainfo."
    log_info "vainfo installed successfully."
}

install_multimedia_arch(){
    log_info "Installing Multimedia Packages for Arch Linux..."

    pkg_install \
        ffmpeg \
        gst-plugins-base \
        gst-plugins-good \
        gst-plugins-bad \
        gst-plugins-ugly \
        gst-libav \
        gst-plugin-va \
        || die "Failed to install Multimedia Packages for Arch Linux."

    log_info "Multimedia Packages for Arch Linux installed successfully."
}

install_multimedia_debian(){
    log_info "Installing Multimedia Packages for Debian and Based Distributions..."

    pkg_install \
        ffmpeg \
        gstreamer1.0-plugins-base \
        gstreamer1.0-plugins-good \
        gstreamer1.0-plugins-bad \
        gstreamer1.0-plugins-ugly \
        gstreamer1.0-libav \
        gstreamer1.0-vaapi \
        || die "Failed to install Multimedia Packages for Debian and Based Distributions."

    log_info "Multimedia Packages for Debian and Based Distributions installed successfully."
}

install_multimedia_fedora(){
    log_info "Installing Multimedia Packages for Fedora and Based Distributions..."

    if ! rpm -q rpmfusion-free-release >/dev/null 2>&1; then
        die "RPM Fusion is required for full multimedia codec support. Enable it first."
    fi

    sudo dnf group install -y multimedia \
        --setopt="install_weak_deps=False" \
        --exclude="PackageKit-gstreamer-plugins" \
        || die "Failed to install Multimedia Packages for Fedora and Based Distributions."

    sudo dnf swap -y 'ffmpeg-free' 'ffmpeg' --allowerasing \
        || die "Failed to swap ffmpeg-free for full ffmpeg."

    log_info "Multimedia Packages for Fedora and Based Distributions installed successfully."
}


install_multimedia(){
    clear

    case "$DISTRO" in
        arch)   install_multimedia_arch ;;
        debian) install_multimedia_debian ;;
        fedora) install_multimedia_fedora ;;
        *) die "Unsupported distribution: $DISTRO" ;;
    esac

    install_vainfo
}

install_multimedia
