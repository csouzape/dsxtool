#!/usr/bin/env bash
set -euo pipefail

install_cups() {
    if pkg_exists "cups"; then 
        log_info "Cups is already installed."
        return 0 
    fi 
    
    log_info "Installing CUPS..."
    pkg_install cups
}

install_epson_driver() {
    log_info "Installing Epson Driver..."

    case "$DISTRO" in
        arch)   pkg_install epson-inkjet-printer-escpr ;;
        debian) pkg_install printer-driver-escpr ;;
        fedora) pkg_install epson-inkjet-printer-escpr ;;
         *)      log_warn "Unsupported distro for epson driver." ;;
    esac
}

install_hp_driver() {
    log_info "Installing HP Driver..."

    case "$DISTRO" in 
        arch) pkg_install hplip ;; 
        debian) pkg_install hplip ;; 
        fedora) pkg_install hplip ;; 
        *)    log_warn "Unsupported distro for HP driver." ;; 
    esac
}

setup_printer() {
    install_cups

    local brand
    brand=$(printf '%s\n' \
        "HP" \
        "Epson" \
        "Other" \
        | _fzf_menu \
              --prompt="Printer brand > " \
              --header="SELECT YOUR PRINTER BRAND  │  [ENTER] select   [ESC] skip" \
              --height=8 \
              --layout=reverse \
              --border=rounded \
              --pointer="▶" \
              --color="bg:#121212,bg+:#1e1e1e,fg:#d1d1d1,fg+:#ffffff,hl:#89b4fa,prompt:#cba6f7,pointer:#f38ba8,header:#f9e2af,border:#2a2a2a" \
              --no-info)

    case "$brand" in
        "HP")    install_hp_driver ;;
        "Epson") install_epson_driver ;;
        "Other") log_warn "No specific driver available. CUPS should detect your printer automatically." ;;
        "")      log_warn "No brand selected. Skipping driver installation." ;;
    esac
}