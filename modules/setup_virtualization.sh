#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────────────────────
# fzf wrapper
# ─────────────────────────────────────────────────────────────────────────────

_fzf_menu() {
    local tmp_in tmp_out
    tmp_in=$(mktemp)
    tmp_out=$(mktemp)
    cat > "$tmp_in"
    fzf "$@" < "$tmp_in" > "$tmp_out" || true
    cat "$tmp_out"
    rm -f "$tmp_in" "$tmp_out"
}

# ─────────────────────────────────────────────────────────────────────────────
# VirtManager (KVM/QEMU) — script original mantido para estabilidade
# ─────────────────────────────────────────────────────────────────────────────

install_virtualization() {
    local -a arch_packages=(
        qemu-desktop virt-manager virt-viewer
        dnsmasq vde2 openbsd-netcat
        nftables iptables-nft libguestfs dmidecode
    )

    local -a debian_packages=(
        qemu-kvm virt-manager virt-viewer
        dnsmasq vde2 netcat-openbsd
        nftables ebtables bridge-utils
        libguestfs-tools dmidecode
    )

    local -a fedora_packages=(
        qemu-kvm virt-manager virt-viewer
        dnsmasq nmap-ncat
        nftables ebtables bridge-utils
        libguestfs-tools dmidecode
    )

    case "$DISTRO" in
        arch)
            log_info "Installing virtualization packages for Arch..."
            sudo pacman -S --noconfirm 2>/dev/null || true
            if ! sudo pacman -S --noconfirm --needed "${arch_packages[@]}"; then
                log_warn "Some packages failed. Trying to install available ones individually..."
                local failed=()
                for pkg in "${arch_packages[@]}"; do
                    sudo pacman -S --noconfirm --needed "$pkg" 2>/dev/null \
                        || { log_warn "Skipping unavailable package: $pkg"; failed+=("$pkg"); }
                done
                if [[ ${#failed[@]} -gt 0 ]]; then
                    log_warn "The following packages could not be installed: ${failed[*]}"
                    log_warn "Try running: sudo pacman -Syyu && sudo pacman -S ${failed[*]}"
                fi
            fi
            ;;
        debian)
            log_info "Installing virtualization packages for Debian/Ubuntu..."
            pkg_install "${debian_packages[@]}" || die "Failed to install virtualization packages."
            ;;
        fedora)
            log_info "Installing virtualization packages for Fedora..."
            pkg_install "${fedora_packages[@]}" || die "Failed to install virtualization packages."
            ;;
        *)
            die "Unsupported distro for virtualization setup: $DISTRO"
            ;;
    esac

    log_info "Virtualization packages installed successfully."
}

_libvirt_setup() {
    local config_file

    if [[ "$DISTRO" == "fedora" ]] && [[ -f "/etc/libvirt/virtqemud.conf" ]]; then
        config_file="/etc/libvirt/virtqemud.conf"
    elif [[ -f "/etc/libvirt/libvirtd.conf" ]]; then
        config_file="/etc/libvirt/libvirtd.conf"
    else
        log_warn "No libvirt config file found — skipping socket config."
        return 0
    fi

    sudo sed -i 's/^[[:space:]]*#[[:space:]]*\(unix_sock_group = "libvirt"\)/\1/' "$config_file"
    sudo sed -i 's/^[[:space:]]*#[[:space:]]*\(unix_sock_rw_perms = "0770"\)/\1/' "$config_file"

    log_info "Libvirt configuration updated: $config_file"
}

_user_setup() {
    local target_user="${SUDO_USER:-${USER:-$(logname)}}"
    sudo usermod -aG libvirt "$target_user" || die "Failed to add $target_user to libvirt group."
    log_info "User $target_user added to libvirt group. Restart session to apply."
}

_service_setup() {
    if [[ "$DISTRO" == "fedora" ]] && systemctl list-unit-files virtqemud.service &>/dev/null; then
        log_info "Enabling virtqemud (modular libvirt for Fedora)..."
        sudo systemctl enable --now virtqemud.socket || die "Failed to enable virtqemud."
        sudo systemctl enable --now virtnetworkd.socket || log_warn "Failed to enable virtnetworkd."
    else
        sudo systemctl enable --now libvirtd || die "Failed to enable/start libvirtd service."
    fi

    log_info "Libvirt service enabled and started."
    sudo virsh net-autostart default 2>/dev/null || log_warn "Failed to set default network to autostart."
    sudo virsh net-start default 2>/dev/null || true
    log_info "Default virtual network configured."
}

_virtualization_installed() {
    case "$DISTRO" in
        arch)   pkg_exists qemu-desktop && pkg_exists virt-manager ;;
        debian) pkg_exists qemu-kvm     && pkg_exists virt-manager ;;
        fedora) pkg_exists qemu-kvm     && pkg_exists virt-manager ;;
        *)      return 1 ;;
    esac
}

_setup_virtmanager() {
    if ! _virtualization_installed; then
        read -rp "Virtualization packages not installed. Install now? (y/n): " confirm < /dev/tty
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            install_virtualization
        else
            log_warn "Skipping virtualization setup."
            return 0
        fi
    else
        log_info "Virtualization packages already installed."
    fi

    _libvirt_setup
    _user_setup
    _service_setup
}

# ─────────────────────────────────────────────────────────────────────────────
# VirtualBox
# ─────────────────────────────────────────────────────────────────────────────

_setup_virtualbox() {
    log_info "Installing VirtualBox..."

    case "$DISTRO" in
        arch)
            pkg_install virtualbox virtualbox-host-modules-arch \
                || die "Failed to install VirtualBox."
            sudo modprobe vboxdrv 2>/dev/null || log_warn "Failed to load vboxdrv module."
            ;;
        debian)
            log_info "Adding VirtualBox repository..."
            local key_file
            key_file=$(mktemp)
            curl -fsSL "https://www.virtualbox.org/download/oracle_vbox_2016.asc" -o "$key_file" \
                || die "Failed to download VirtualBox signing key."
            sudo gpg --dearmor -o /usr/share/keyrings/virtualbox.gpg "$key_file" \
                || { rm -f "$key_file"; die "Failed to install VirtualBox signing key."; }
            rm -f "$key_file"
            echo "deb [arch=amd64 signed-by=/usr/share/keyrings/virtualbox.gpg] \
                https://download.virtualbox.org/virtualbox/debian $(lsb_release -cs) contrib" \
                | sudo tee /etc/apt/sources.list.d/virtualbox.list
            sudo apt-get update -y
            pkg_install virtualbox-7.0 || die "Failed to install VirtualBox."
            ;;
        fedora)
            log_info "Adding VirtualBox repository..."
            sudo dnf config-manager --add-repo \
                https://download.virtualbox.org/virtualbox/rpm/fedora/virtualbox.repo
            pkg_install VirtualBox || die "Failed to install VirtualBox."
            ;;
        *)
            die "Unsupported distro for VirtualBox: $DISTRO"
            ;;
    esac

    local target_user="${SUDO_USER:-${USER:-$(logname)}}"
    sudo usermod -aG vboxusers "$target_user" \
        && log_info "User $target_user added to vboxusers group." \
        || log_warn "Failed to add user to vboxusers group."

    log_info "VirtualBox installed successfully. Restart session to apply group changes."
}

# ─────────────────────────────────────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────────────────────────────────────

setup_virtualization() {
    local choice
    choice=$(printf '%s\n' \
        "  virt-manager (KVM/QEMU) — recommended" \
        "  VirtualBox" \
        "  Exit" \
        | _fzf_menu \
              --prompt="Virtualization > " \
              --header="SELECT VIRTUALIZATION SOLUTION  │  [ENTER] select   [ESC] back" \
              --height=8 \
              --layout=reverse \
              --border=rounded \
              --pointer="▶" \
              --color="bg:#121212,bg+:#1e1e1e,fg:#d1d1d1,fg+:#ffffff,hl:#89b4fa,prompt:#cba6f7,pointer:#f38ba8,header:#f9e2af,border:#2a2a2a" \
              --no-info)

    case "$choice" in
        *"virt-manager"*) _setup_virtmanager ;;
        *"VirtualBox"*)   _setup_virtualbox ;;
        *"Exit"|"")       return 0 ;;
    esac
}