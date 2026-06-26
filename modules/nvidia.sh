#!/usr/bin/env bash
set -uo pipefail
# NVIDIA driver setup for dsxtool.

NVIDIA_FOUND=0
NVIDIA_MODEL=""
NVIDIA_PCI_ID=""
NVIDIA_DRIVER_SERIES=""

detect_gpu() {
    if ! command -v lspci >/dev/null 2>&1; then
        log_warn "lspci not found; installing pciutils..."
        pkg_install pciutils || die "Failed to install pciutils."
    fi

    local line
    line=$(lspci -nn | grep -Ei 'vga|3d|display' | grep -i 'nvidia' | head -n 1)

    if [[ -z "$line" ]]; then
        NVIDIA_FOUND=0
        return 1
    fi

    NVIDIA_FOUND=1
    NVIDIA_MODEL=$(echo "$line" | sed -E 's/.*NVIDIA Corporation //; s/ \(rev .*//; s/ \[[0-9a-f:]+\]//')
    NVIDIA_PCI_ID=$(echo "$line" | grep -oE '10de:[0-9a-f]{4}' | head -n 1 | cut -d: -f2)

    log_info "Detected NVIDIA GPU: $NVIDIA_MODEL (PCI ID: 10de:${NVIDIA_PCI_ID:-unknown})"
    return 0
}


detect_nvidia_generation() {
    local m="${NVIDIA_MODEL,,}"
    if [[ "$m" =~ rtx[[:space:]]*(20|30|40|50)|gtx[[:space:]]*16|[[:space:]](a|h)[0-9]{3,4} ]]; then
        NVIDIA_DRIVER_SERIES="current"
        return
    fi
    if [[ "$m" =~ gtx[[:space:]]*10|titan[[:space:]]*(x|xp|v)|[[:space:]]p[0-9]{2,3}|v100 ]]; then
        NVIDIA_DRIVER_SERIES="current"
        return
    fi
    if [[ "$m" =~ gtx[[:space:]]*9|gtx[[:space:]]*750|gtx[[:space:]]*titan[[:space:]]*x ]]; then
        NVIDIA_DRIVER_SERIES="current"
        return
    fi
    if [[ "$m" =~ gtx[[:space:]]*[67]|gt[[:space:]]*[67][0-9]{2}|kepler ]]; then
        NVIDIA_DRIVER_SERIES="legacy_470"
        return
    fi
    if [[ "$m" =~ gtx[[:space:]]*[45]|gt[[:space:]]*[45][0-9]{2}|fermi ]]; then
        NVIDIA_DRIVER_SERIES="legacy_390"
        return
    fi

    log_warn "Could not auto-detect generation for '$NVIDIA_MODEL'; defaulting to current driver."
    NVIDIA_DRIVER_SERIES="current"
}

_secure_boot_warning() {
    if [[ -d /sys/firmware/efi ]] && command -v mokutil >/dev/null 2>&1; then
        if mokutil --sb-state 2>/dev/null | grep -qi 'enabled'; then
            log_warn "Secure Boot is enabled. NVIDIA kernel modules must be signed (MOK) or the system will boot without 3D acceleration."
        fi
    fi
}

_install_nvidia_arch() {
    local running_kernel
    running_kernel="$(uname -r)"

    local pkgs=()
    case "$NVIDIA_DRIVER_SERIES" in
        current)
            pkgs+=(nvidia-dkms nvidia-utils lib32-nvidia-utils nvidia-settings libva-nvidia-driver egl-wayland)
            if [[ "$running_kernel" == *lts* ]]; then
                pkgs+=(linux-lts-headers)
            elif [[ "$running_kernel" == *zen* ]]; then
                pkgs+=(linux-zen-headers)
            elif [[ "$running_kernel" == *hardened* ]]; then
                pkgs+=(linux-hardened-headers)
            else
                pkgs+=(linux-headers)
            fi
            pkg_install "${pkgs[@]}" || die "Failed to install NVIDIA driver packages."
            ;;
        legacy_470|legacy_390)
            require_aur_helper
            local aur_pkg
            if [[ "$NVIDIA_DRIVER_SERIES" == "legacy_470" ]]; then
                aur_pkg="nvidia-470xx-dkms"
            else
                aur_pkg="nvidia-390xx-dkms"
            fi
            log_info "Installing $aur_pkg from AUR..."
            aur_install --needed "$aur_pkg" linux-headers nvidia-settings || die "Failed to install $aur_pkg."
            ;;
    esac
}

_install_nvidia_debian() {
    if [[ "${ID:-}" == "ubuntu" ]] || command -v ubuntu-drivers >/dev/null 2>&1; then
        log_info "Using ubuntu-drivers to install the recommended NVIDIA driver..."
        pkg_install ubuntu-drivers-common || die "Failed to install ubuntu-drivers-common."
        sudo ubuntu-drivers autoinstall || die "ubuntu-drivers autoinstall failed."
        pkg_install libnvidia-encode1 libnvidia-decode1 nvidia-settings || log_warn "Optional NVIDIA extras did not install cleanly."
        return
    fi

    log_info "Enabling contrib/non-free repositories for Debian..."
    if ! grep -qE 'non-free(-firmware)?' /etc/apt/sources.list 2>/dev/null; then
        sudo sed -i -E 's/^(deb .*main)$/\1 contrib non-free non-free-firmware/' /etc/apt/sources.list || true
    fi
    sudo apt-get update -y || die "apt-get update failed."

    sudo dpkg --add-architecture i386
    sudo apt-get update -y

    local pkgs=(linux-headers-amd64 firmware-misc-nonfree nvidia-settings)
    case "$NVIDIA_DRIVER_SERIES" in
        current)     pkgs+=(nvidia-driver libgl1-nvidia-glvnd-glx:i386) ;;
        legacy_470)  pkgs+=(nvidia-tesla-470-driver) ;;
        legacy_390)  pkgs+=(nvidia-legacy-390xx-driver) ;;
    esac

    pkg_install "${pkgs[@]}" || die "Failed to install NVIDIA driver packages."
}

_install_nvidia_fedora() {
    local fedora_ver
    fedora_ver=$(rpm -E %fedora)

    log_info "Enabling RPM Fusion (nonfree)..."
    sudo dnf install -y \
        "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${fedora_ver}.noarch.rpm" \
        "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${fedora_ver}.noarch.rpm" \
        || die "Failed to enable RPM Fusion."

    sudo dnf upgrade -y --refresh || log_warn "Refresh upgrade returned warnings, continuing."

    local pkgs=(kernel-devel kernel-headers)
    case "$NVIDIA_DRIVER_SERIES" in
        current)
            pkgs+=(akmod-nvidia xorg-x11-drv-nvidia-cuda xorg-x11-drv-nvidia-libs.i686 nvidia-vaapi-driver)
            ;;
        legacy_470)
            pkgs+=(akmod-nvidia-470xx xorg-x11-drv-nvidia-470xx-cuda xorg-x11-drv-nvidia-470xx-libs.i686)
            ;;
        legacy_390)
            pkgs+=(akmod-nvidia-390xx xorg-x11-drv-nvidia-390xx-cuda xorg-x11-drv-nvidia-390xx-libs.i686)
            ;;
    esac

    pkg_install "${pkgs[@]}" || die "Failed to install NVIDIA driver packages."

    log_info "Building akmod kernel module (this may take a few minutes)..."
    sudo akmods --force || log_warn "akmods build returned a non-zero status; check /var/cache/akmods/."
}

_configure_nvidia_modeset() {
    log_info "Enabling NVIDIA DRM kernel modesetting (required for Wayland and tearing-free X11)..."

    local conf=/etc/modprobe.d/nvidia.conf
    sudo tee "$conf" >/dev/null <<'EOF'
options nvidia-drm modeset=1 fbdev=1
options nvidia NVreg_PreserveVideoMemoryAllocations=1
EOF

    case "$DISTRO" in
        arch)
            if [[ -f /etc/mkinitcpio.conf ]]; then
                if ! grep -qE '^MODULES=.*nvidia' /etc/mkinitcpio.conf; then
                    sudo sed -i -E 's/^(MODULES=\()/\1nvidia nvidia_modeset nvidia_uvm nvidia_drm /' /etc/mkinitcpio.conf
                fi
                sudo mkinitcpio -P || log_warn "mkinitcpio regeneration returned warnings."
            fi
            ;;
        debian)
            sudo update-initramfs -u || log_warn "update-initramfs returned warnings."
            ;;
        fedora)
            sudo dracut --force || log_warn "dracut returned warnings."
            ;;
    esac
}

setup_nvidia() {
    log_info "Starting NVIDIA driver setup..."
    require_sudo

    if ! detect_gpu; then
        log_warn "No NVIDIA GPU detected on this system."
        read -rp "Continue anyway and install the current proprietary driver? (y/n): " confirm < /dev/tty
        [[ "$confirm" =~ ^[Yy]$ ]] || { log_warn "NVIDIA setup cancelled."; return 0; }
        NVIDIA_MODEL="unknown"
        NVIDIA_DRIVER_SERIES="current"
    else
        detect_nvidia_generation
        log_info "Driver series selected: $NVIDIA_DRIVER_SERIES"
    fi

    _secure_boot_warning

    echo ""
    log_warn "This will install proprietary NVIDIA drivers, 32-bit libs and enable DRM modeset."
    log_warn "A reboot is required after the installation finishes."
    read -rp "Continue? (y/n): " confirm < /dev/tty
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        log_warn "NVIDIA setup cancelled."
        return 0
    fi

    case "$DISTRO" in
        arch)   _install_nvidia_arch ;;
        debian) _install_nvidia_debian ;;
        fedora) _install_nvidia_fedora ;;
        *)      die "Unsupported distro for NVIDIA setup: $DISTRO" ;;
    esac

    _configure_nvidia_modeset

    log_info "NVIDIA setup completed."
    log_info "Reboot to load the new driver. After reboot, verify with: nvidia-smi"
}
4