#!/usr/bin/env bash
set -uo pipefail
# GPU driver dispatcher for dsxtool.
# Detects the GPU vendor(s) present and installs the right driver stack.
# NVIDIA is delegated entirely to the dedicated modules/nvidia.sh script.

GPU_HAS_NVIDIA=0
GPU_HAS_AMD=0
GPU_HAS_INTEL=0

detect_gpu_vendors() {
    if ! command -v lspci >/dev/null 2>&1; then
        log_warn "lspci not found; installing pciutils..."
        pkg_install pciutils || die "Failed to install pciutils."
    fi

    local gpu_lines
    gpu_lines=$(lspci -nn | grep -Ei 'vga|3d|display')

    if [[ -z "$gpu_lines" ]]; then
        log_warn "No GPU controllers found via lspci."
        return 1
    fi

    grep -qi 'nvidia' <<< "$gpu_lines" && GPU_HAS_NVIDIA=1
    grep -Eqi '\<(amd|ati|radeon)\>' <<< "$gpu_lines" && GPU_HAS_AMD=1
    grep -qi 'intel' <<< "$gpu_lines" && GPU_HAS_INTEL=1

    log_info "GPU(s) detected:"
    while IFS= read -r line; do
        log_info "  - $(sed -E 's/.*: //; s/ \(rev .*//' <<< "$line")"
    done <<< "$gpu_lines"

    return 0
}

_install_drivers_amd_arch() {
    log_info "Installing AMD graphics stack (Arch)..."
    pkg_install \
        mesa lib32-mesa \
        vulkan-radeon lib32-vulkan-radeon \
        libva-mesa-driver lib32-libva-mesa-driver \
        mesa-vdpau lib32-mesa-vdpau \
        || die "Failed to install AMD driver packages."
}

_install_drivers_amd_debian() {
    log_info "Installing AMD graphics stack (Debian/Ubuntu)..."
    sudo dpkg --add-architecture i386 2>/dev/null || true
    sudo apt-get update -y || die "apt-get update failed."
    pkg_install \
        mesa-vulkan-drivers libgl1-mesa-dri \
        mesa-va-drivers mesa-vdpau-drivers \
        firmware-amd-graphics \
        || die "Failed to install AMD driver packages."
}

_install_drivers_amd_fedora() {
    log_info "Installing AMD graphics stack (Fedora)..."
    if ! rpm -q rpmfusion-free-release >/dev/null 2>&1; then
        log_warn "RPM Fusion (free) not found; some AMD VA-API/VDPAU packages may be unavailable."
    fi
    pkg_install \
        mesa-dri-drivers mesa-vulkan-drivers \
        mesa-va-drivers mesa-vdpau-drivers \
        || die "Failed to install AMD driver packages."
}

_install_drivers_intel_arch() {
    log_info "Installing Intel graphics stack (Arch)..."
    pkg_install \
        mesa lib32-mesa \
        vulkan-intel lib32-vulkan-intel \
        intel-media-driver libva-intel-driver \
        || die "Failed to install Intel driver packages."
}

_install_drivers_intel_debian() {
    log_info "Installing Intel graphics stack (Debian/Ubuntu)..."
    sudo dpkg --add-architecture i386 2>/dev/null || true
    sudo apt-get update -y || die "apt-get update failed."
    pkg_install \
        mesa-vulkan-drivers libgl1-mesa-dri \
        intel-media-va-driver \
        || die "Failed to install Intel driver packages."
}

_install_drivers_intel_fedora() {
    log_info "Installing Intel graphics stack (Fedora)..."
    pkg_install \
        mesa-dri-drivers mesa-vulkan-drivers \
        intel-media-driver libva-intel-driver \
        || die "Failed to install Intel driver packages."
}

_install_drivers_amd() {
    case "$DISTRO" in
        arch)   _install_drivers_amd_arch ;;
        debian) _install_drivers_amd_debian ;;
        fedora) _install_drivers_amd_fedora ;;
        *)      die "Unsupported distro for AMD driver setup: $DISTRO" ;;
    esac
}

_install_drivers_intel() {
    case "$DISTRO" in
        arch)   _install_drivers_intel_arch ;;
        debian) _install_drivers_intel_debian ;;
        fedora) _install_drivers_intel_fedora ;;
        *)      die "Unsupported distro for Intel driver setup: $DISTRO" ;;
    esac
}

setup_drivers() {
    log_info "Starting GPU driver setup..."

    if ! detect_gpu_vendors; then
        log_warn "No supported GPU vendor detected. Skipping driver setup."
        return 0
    fi

    if [[ "$GPU_HAS_NVIDIA" -eq 1 ]]; then
        log_info "NVIDIA GPU detected — delegating to the dedicated NVIDIA module."
        source "$BASE_DIR/modules/nvidia.sh"
        setup_nvidia
    fi

    if [[ "$GPU_HAS_AMD" -eq 1 ]]; then
        _install_drivers_amd
    fi

    if [[ "$GPU_HAS_INTEL" -eq 1 ]]; then
        _install_drivers_intel
    fi

    if [[ "$GPU_HAS_NVIDIA" -eq 0 && "$GPU_HAS_AMD" -eq 0 && "$GPU_HAS_INTEL" -eq 0 ]]; then
        log_warn "GPU controller(s) found, but vendor could not be identified (not NVIDIA/AMD/Intel)."
    fi

    log_info "Driver setup completed."
}