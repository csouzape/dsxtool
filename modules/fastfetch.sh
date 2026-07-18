#!/usr/bin/env bash

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

FASTFETCH_AVAILABLE_MODULES=(
    "title" "separator" "os" "host" "kernel" "uptime" "packages"
    "shell" "display" "de" "wm" "wmtheme" "icons" "font" "cursor"
    "terminal" "terminalfont" "cpu" "gpu" "memory" "swap" "disk"
    "localip" "battery" "poweradapter" "locale" "break" "colors"
)

FASTFETCH_DEFAULT_MODULES=(
    "title" "separator" "os" "kernel" "uptime" "packages" "shell"
    "de" "wm" "terminal" "cpu" "gpu" "memory" "disk" "break" "colors"
)

fastfetch_pick_modules() {
    if ! command -v fzf &>/dev/null; then
        log_warn "fzf not found, using default modules."
        printf '%s\n' "${FASTFETCH_DEFAULT_MODULES[@]}"
        return 0
    fi

    local chosen
    chosen="$(printf '%s\n' "${FASTFETCH_AVAILABLE_MODULES[@]}" | \
        fzf --multi --height=60% --border \
            --header="TAB for select, ENTER to confirm" \
            --prompt="Fastfetch modules > ")"

    if [[ -z "$chosen" ]]; then
        log_warn "Any module selected, using default modules."
        printf '%s\n' "${FASTFETCH_DEFAULT_MODULES[@]}"
        return 0
    fi

    printf '%s\n' "$chosen"
}

fastfetch_pick_color() {
    local colors=("blue" "cyan" "green" "magenta" "red" "yellow" "white" "default")
    local chosen

    if command -v fzf &>/dev/null; then
        chosen="$(printf '%s\n' "${colors[@]}" | \
            fzf --height=40% --border --prompt="Cor do logo > ")"
    else
        read -rp "$(echo -e "${YELLOW}Logo color (blue/cyan/green/magenta/red/yellow/white/default): ${RESET}")" chosen < /dev/tty
    fi

    echo "${chosen:-blue}"
}

build_fastfetch_json() {
    local config_file="$1"
    shift
    local modules=("$@")
    local color
    color="$(fastfetch_pick_color)"

    {
        echo '{'
        echo '    "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",'
        echo '    "logo": {'
        echo '        "type": "auto",'
        echo '        "color": { "1": "'"$color"'" }'
        echo '    },'
        echo '    "display": { "separator": "  " },'
        echo '    "modules": ['
        local i last=$((${#modules[@]} - 1))
        for i in "${!modules[@]}"; do
            if [[ "$i" -eq "$last" ]]; then
                echo '        "'"${modules[$i]}"'"'
            else
                echo '        "'"${modules[$i]}"'",'
            fi
        done
        echo '    ]'
        echo '}'
    } > "$config_file"
}

setup_fastfetch_config() {
    local config_dir="$HOME/.config/fastfetch"
    local config_file="$config_dir/config.jsonc"

    if [[ -d "$config_dir" && ! -d "${config_dir}-bak" ]]; then
        cp -r "$config_dir" "${config_dir}-bak"
        log_info "Existing configuration backed up to ${config_dir}-bak."
    fi

    mkdir -p "$config_dir"

    local mode
    read -rp "$(echo -e "${YELLOW}Fastfetch Config: [d]sxtool default / [c]ustomize now / [e]dit manually (d/c/e): ${RESET}")" mode < /dev/tty
    mode="${mode:-p}"

    case "$mode" in
        c|C)
            log_info "Select the modules to display."
            mapfile -t selected_modules < <(fastfetch_pick_modules)
            build_fastfetch_json "$config_file" "${selected_modules[@]}"
            log_info "Custom configuration saved to $config_file."
            ;;
        e|E)
            build_fastfetch_json "$config_file" "${FASTFETCH_DEFAULT_MODULES[@]}"
            "${EDITOR:-nano}" "$config_file"
            log_info "Manual edit saved to $config_file."
            ;;
        *)
            if curl -fsSLo "$config_file" "$FASTFETcH_CONFIG_URL"; then
                log_info "Fastfetch configuration downloaded to $config_file."
            else
                log_warn "Could not download config, writing built-in default instead."
                build_fastfetch_json "$config_file" "${FASTFETCH_DEFAULT_MODULES[@]}"
            fi
            ;;
    esac
}

FASTFETCH_CONFIG_URL="${FASTFETCH_CONFIG_URL:-https://raw.githubusercontent.com/csouzape/bashconfig/main/fastfetch/config.jsonc}"

open_in_editor() {
    local file="$1"
    local candidates=("nvim" "vim" "nano" "vi" "emacs" "code" "micro")
    local available=()
    local editor_bin

    if [[ -n "$EDITOR" ]] && command -v "$EDITOR" &>/dev/null; then
        available+=("$EDITOR")
    fi
    if [[ -n "$VISUAL" && "$VISUAL" != "$EDITOR" ]] && command -v "$VISUAL" &>/dev/null; then
        available+=("$VISUAL")
    fi

    local candidate
    for candidate in "${candidates[@]}"; do
        if command -v "$candidate" &>/dev/null; then
            if [[ ! " ${available[*]} " =~ " ${candidate} " ]]; then
                available+=("$candidate")
            fi
        fi
    done

    if [[ "${#available[@]}" -eq 0 ]]; then
        log_warn "Any editor found. Edit manually: $file"
        return 0
    fi

    if [[ "${#available[@]}" -eq 1 ]]; then
        editor_bin="${available[0]}"
        log_info "Using $editor_bin (Only editor available)."
    elif command -v fzf &>/dev/null; then
        editor_bin="$(printf '%s\n' "${available[@]}" | \
            fzf --height=40% --border --prompt="Choice the editor > ")"
    else
        log_info "Available editors:"
        local i
        for i in "${!available[@]}"; do
            echo "  $((i+1))) ${available[$i]}"
        done
        local choice
        read -rp "$(echo -e "${YELLOW}Choice the editor (number): ${RESET}")" choice < /dev/tty
        editor_bin="${available[$((choice-1))]}"
    fi

    if [[ -z "$editor_bin" ]]; then
        log_warn "No editor selected. Skipping manual edit."
        return 0
    fi

    "$editor_bin" "$file" < /dev/tty
}

setup_fastfetch_config() {
    local config_dir="$HOME/.config/fastfetch"
    local config_file="$config_dir/config.jsonc"

    if [[ -d "$config_dir" && ! -d "${config_dir}-bak" ]]; then
        cp -r "$config_dir" "${config_dir}-bak"
        log_info "Existing configuration backed up to ${config_dir}-bak."
    fi

    mkdir -p "$config_dir"

    local mode
    read -rp "$(echo -e "${YELLOW}Fastfetch Config: [d]sxtool default / [c]ustomize now / [e]edit json manually (d/c/e): ${RESET}")" mode < /dev/tty
    mode="${mode:-p}"

    case "$mode" in
        c|C)
            log_info "Select the modules to display."
            local selected_modules
            mapfile -t selected_modules < <(fastfetch_pick_modules)
            build_fastfetch_json "$config_file" "${selected_modules[@]}"
            log_info "Config save on $config_file."
            ;;
        e|E)
            build_fastfetch_json "$config_file" "${FASTFETCH_DEFAULT_MODULES[@]}"
            open_in_editor "$config_file"
            log_info "Config saved on $config_file."
            ;;
        *)
            if curl -fsSLo "$config_file" "$FASTFETCH_CONFIG_URL"; then
                log_info "Fastfetch configuration downloaded to $config_file."
            else
                log_warn "Could not download config, writing built-in default instead."
                build_fastfetch_json "$config_file" "${FASTFETCH_DEFAULT_MODULES[@]}"
                log_info "Fastfetch configuration written to $config_file."
            fi
            ;;
    esac
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
