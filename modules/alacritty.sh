#!/usr/bin/env bash
set -euo pipefail

source "${BASE_DIR}/core/common.sh"
source "${BASE_DIR}/core/detect.sh"
source "${BASE_DIR}/core/distros/$DISTRO.sh"

install_alacritty() {
    if pkg_exists "alacritty"; then
        log_info "Alacritty is already installed."
        return 0
    fi

    log_info "Installing Alacritty..."
    pkg_install "alacritty" || die "Failed to install Alacritty."
    log_info "Alacritty installed successfully."

    prompt_csouzape_config
}

prompt_csouzape_config() {
    read -rp "Install csouzape's Alacritty configuration? (y/n): " confirm < /dev/tty
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        apply_csouzape_alacritty_config
    else
        log_warn "Configuration skipped."
    fi
}

apply_csouzape_alacritty_config() {
    log_info "Applying csouzape's Alacritty configuration..."
    mkdir -p "$HOME/.config/alacritty"

    cat > "$HOME/.config/alacritty/alacritty.yml" << 'EOF'
window:
  opacity: 0.6

font:
  size: 12.0
  normal:
    family: JetBrains Mono
    style: Regular

colors:
  primary:
    background: '#0f0f0f'
EOF

    log_info "Configuration saved to ~/.config/alacritty/alacritty.yml"
}

