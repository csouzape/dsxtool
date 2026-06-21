#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# dsxtool · Fastfetch module
# ---------------------------------------------------------------------------
# Installs fastfetch, deploys a default configuration (backing up any existing
# one) and optionally wires it into the user's shell startup file.
# ---------------------------------------------------------------------------

install_fastfetch() {
    if command -v fastfetch &>/dev/null; then
        log_info "Fastfetch is already installed."
        return 0
    fi

    log_info "Installing Fastfetch..."
    case "$DISTRO" in
        arch)
            pkg_install fastfetch
            ;;
        debian)
            local arch deb_file
            arch="$(uname -m)"
            case "$arch" in
                x86_64)  deb_file="fastfetch-linux-amd64.deb" ;;
                aarch64) deb_file="fastfetch-linux-aarch64.deb" ;;
                *)       deb_file="" ;;
            esac

            if [[ -n "$deb_file" ]]; then
                local tmp_deb="/tmp/fastfetch.deb"
                if curl -fsSLo "$tmp_deb" \
                    "https://github.com/fastfetch-cli/fastfetch/releases/latest/download/$deb_file"; then
                    sudo apt-get install -y "$tmp_deb" || pkg_install fastfetch
                    rm -f "$tmp_deb"
                else
                    log_warn "Could not download the .deb, falling back to apt."
                    pkg_install fastfetch
                fi
            else
                pkg_install fastfetch
            fi
            ;;
        fedora)
            pkg_install fastfetch
            ;;
        *)
            log_error "Unsupported distro for fastfetch: $DISTRO"
            return 1
            ;;
    esac

    if command -v fastfetch &>/dev/null; then
        log_info "Fastfetch installed successfully."
    else
        log_error "Fastfetch installation failed."
        return 1
    fi
}

setup_fastfetch_config() {
    local config_dir="$HOME/.config/fastfetch"
    local config_file="$config_dir/config.jsonc"

    # Back up an existing configuration once before overwriting it.
    if [[ -d "$config_dir" && ! -d "${config_dir}-bak" ]]; then
        cp -r "$config_dir" "${config_dir}-bak"
        log_info "Existing configuration backed up to ${config_dir}-bak."
    fi

    mkdir -p "$config_dir"
    cat > "$config_file" <<'EOL'
{
    "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
    "logo": { "type": "auto" },
    "display": { "separator": "  " },
    "modules": [
        "title",
        "separator",
        "os",
        "kernel",
        "uptime",
        "packages",
        "shell",
        "de",
        "wm",
        "terminal",
        "cpu",
        "gpu",
        "memory",
        "disk",
        "break",
        "colors"
    ]
}
EOL
    log_info "Fastfetch configuration written to $config_file."
}

setup_fastfetch_shell() {
    local current_shell rc_file
    current_shell="$(basename "${SHELL:-}")"

    case "$current_shell" in
        bash) rc_file="$HOME/.bashrc" ;;
        zsh)  rc_file="$HOME/.zshrc" ;;
        fish) rc_file="$HOME/.config/fish/config.fish" ;;
        *)
            log_warn "Shell '$current_shell' is not supported for automatic integration. Add 'fastfetch' to your shell config manually."
            return 0
            ;;
    esac

    if [[ -f "$rc_file" ]] && grep -q "fastfetch" "$rc_file"; then
        log_info "Fastfetch is already configured in $rc_file."
        return 0
    fi

    local answer
    read -rp "$(echo -e "${YELLOW}Run fastfetch on every new shell? Adds it to $rc_file (y/n): ${RESET}")" answer < /dev/tty
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        mkdir -p "$(dirname "$rc_file")"
        printf '\n# Run fastfetch on shell initialization\nfastfetch\n' >> "$rc_file"
        log_info "Added fastfetch to $rc_file."
    else
        log_info "Skipped shell integration."
    fi
}

setup_fastfetch() {
    install_fastfetch || return 1
    setup_fastfetch_config
    setup_fastfetch_shell
}
