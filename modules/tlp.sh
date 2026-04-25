#!/usr/bin/env bash
set -euo pipefail

install_tlp() {
    if pkg_exists tlp; then
        log_info "TLP is already installed."
        return 0
    fi
    log_info "Installing TLP..."
    pkg_install tlp || die "Failed to install TLP."
    log_info "Enabling and starting TLP service..."
    sudo systemctl enable tlp || log_warn "Failed to enable TLP service."
    sudo systemctl start tlp  || log_warn "Failed to start TLP service."
    log_info "TLP installed and started successfully."
}

detect_manager() {
    if systemctl is-active --quiet "tlp" 2>/dev/null; then
        echo "tlp"
        return 0
    fi

    for bin in tuned power-profiles-daemon system76-power; do
        if command -v "$bin" &>/dev/null; then
            echo "$bin"
            return 0
        fi
    done

    local services=(
        "power-profiles-daemon"
        "tuned"
        "system76-power"
        "upower"
    )
    for svc in "${services[@]}"; do
        if systemctl is-active --quiet "$svc" 2>/dev/null; then
            echo "$svc"
            return 0
        fi
    done

    for svc in "${services[@]}"; do
        if systemctl is-enabled --quiet "$svc" 2>/dev/null; then
            echo "$svc"
            return 0
        fi
    done

    if command -v tlp &>/dev/null; then
        echo "tlp"
        return 0
    fi

    return 1
}

manager_to_package() {
    local manager="$1"
    case "$DISTRO:$manager" in
        arch:tlp|debian:tlp|fedora:tlp)
            echo "tlp" ;;
        arch:tuned|debian:tuned|fedora:tuned)
            echo "tuned" ;;
        arch:power-profiles-daemon|debian:power-profiles-daemon|fedora:power-profiles-daemon)
            echo "power-profiles-daemon" ;;
        arch:system76-power|debian:system76-power|fedora:system76-power)
            echo "system76-power" ;;
        *:upower)
            echo "" ;;
        *)
            echo "" ;;
    esac
}

_remove_manager() {
    local manager="$1"
    local manager_pkg
    manager_pkg="$(manager_to_package "$manager")"
    if [[ -n "$manager_pkg" ]]; then
        if pkg_exists "$manager_pkg"; then
            log_info "Removing '$manager_pkg'..."
            pkg_remove "$manager_pkg" || log_warn "Failed to remove '$manager_pkg'."
        else
            log_warn "Package '$manager_pkg' not found. Stopping service only..."
            sudo systemctl stop "$manager" 2>/dev/null    || true
            sudo systemctl disable "$manager" 2>/dev/null || true
        fi
    else
        log_warn "No package mapping for '$manager'. Stopping service only..."
        sudo systemctl stop "$manager" 2>/dev/null    || true
        sudo systemctl disable "$manager" 2>/dev/null || true
    fi
}

replace_manager_with_tlp() {
    local manager
    manager=$(detect_manager || true)

    if [[ "$manager" == "tlp" ]]; then
        log_info "TLP is already configured and running."
        read -rp "Do you want to replace TLP with another power manager? (y/n): " confirm < /dev/tty
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            _remove_manager "tlp"
            log_info "TLP removed. You can now install another power manager manually."
        else
            log_warn "No changes made."
        fi
        return
    fi

    if [[ -z "$manager" ]]; then
        log_warn "No active power manager detected."
        read -rp "Do you want to install and configure TLP? (y/n): " confirm < /dev/tty
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            install_tlp
        else
            log_warn "Skipping TLP installation."
        fi
        return
    fi

    log_info "Detected power manager: $manager"
    log_info "Replacing '$manager' with TLP..."
    _remove_manager "$manager"
    install_tlp
    log_info "Configuration complete."
}

check_manager() {
    detect_manager >/dev/null 2>&1
}