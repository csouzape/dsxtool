#!/usr/bin/env bash
set -uo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export BASE_DIR

source "$BASE_DIR/core/common.sh"
source "$BASE_DIR/core/detect.sh"

detect_distro

if [[ ! -f "$BASE_DIR/core/distros/$DISTRO.sh" ]]; then
    die "Unsupported distro: $DISTRO"
fi

source "$BASE_DIR/core/distros/$DISTRO.sh"


verify_fzf_tool() {
    if command -v fzf >/dev/null 2>&1; then
        return
    fi

    log_info "fzf not found."

    if [[ ! -t 0 ]]; then
        log_info "Non-interactive mode detected. Installing fzf..."
        pkg_install fzf || die "Failed to install fzf."
        return
    fi

    while true; do
        read -rp "Install fzf now? [y/n]: " answer < /dev/tty
        case "$answer" in
            [Yy]) pkg_install fzf || die "Failed to install fzf."; return ;;
            [Nn]) die "fzf is required." ;;
        esac
    done
}

setup_alias() {
    local shell_rc=""
    local alias_definition=""
    local alias_pattern=""
    local remove_pattern=""
    local answer=""
    local shell_name

    shell_name="$(basename "${SHELL:-}" )"
    if [[ -z "$shell_name" ]]; then
        shell_name="$(basename "$(ps -p $$ -o comm= 2>/dev/null || true)")"
    fi

    case "$shell_name" in
        zsh)
            shell_rc="$HOME/.zshrc"
            alias_definition="alias dsxtool='curl -fsSL https://raw.githubusercontent.com/csouzape/dsxtool/main/bootstrap.sh | bash'"
            alias_pattern='^[[:space:]]*alias[[:space:]]+dsxtool='
            remove_pattern='^[[:space:]]*alias[[:space:]]+dsxtool='
            ;;
        bash)
            if shopt -q login_shell 2>/dev/null; then
                if [[ -f "$HOME/.bash_profile" ]]; then
                    shell_rc="$HOME/.bash_profile"
                elif [[ -f "$HOME/.bash_login" ]]; then
                    shell_rc="$HOME/.bash_login"
                elif [[ -f "$HOME/.profile" ]]; then
                    shell_rc="$HOME/.profile"
                else
                    shell_rc="$HOME/.bash_profile"
                fi
            else
                shell_rc="$HOME/.bashrc"
            fi
            alias_definition="alias dsxtool='curl -fsSL https://raw.githubusercontent.com/csouzape/dsxtool/main/bootstrap.sh | bash'"
            alias_pattern='^[[:space:]]*alias[[:space:]]+dsxtool='
            remove_pattern='^[[:space:]]*alias[[:space:]]+dsxtool='
            ;;
        fish)
            shell_rc="$HOME/.config/fish/config.fish"
            alias_definition="alias dsxtool 'curl -fsSL https://raw.githubusercontent.com/csouzape/dsxtool/main/bootstrap.sh | bash'"
            alias_pattern='^[[:space:]]*alias[[:space:]]+dsxtool'
            remove_pattern='^[[:space:]]*alias[[:space:]]+dsxtool'
            ;;
        ksh)
            shell_rc="$HOME/.kshrc"
            alias_definition="alias dsxtool='curl -fsSL https://raw.githubusercontent.com/csouzape/dsxtool/main/bootstrap.sh | bash'"
            alias_pattern='^[[:space:]]*alias[[:space:]]+dsxtool='
            remove_pattern='^[[:space:]]*alias[[:space:]]+dsxtool='
            ;;
        *)
            shell_rc="$HOME/.profile"
            alias_definition="alias dsxtool='curl -fsSL https://raw.githubusercontent.com/csouzape/dsxtool/main/bootstrap.sh | bash'"
            alias_pattern='^[[:space:]]*alias[[:space:]]+dsxtool'
            remove_pattern='^[[:space:]]*alias[[:space:]]+dsxtool'
            log_warn "Shell '$shell_name' is not explicitly supported; writing alias to $shell_rc."
            ;;
    esac

    mkdir -p "$(dirname "$shell_rc")"
    touch "$shell_rc"
    echo ""

    if grep -qE "$alias_pattern" "$shell_rc"; then
        log_info "Alias 'dsxtool' already exists in $shell_rc. Skipping setup."
        return 0
    fi

    read -rp "Would you like to set up the 'dsxtool' alias for easy access? [y/n]: " answer < /dev/tty
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        echo "$alias_definition" >> "$shell_rc"
        log_info "Alias 'dsxtool' added to $shell_rc. Please restart your terminal or run 'source $shell_rc' to apply."
    else
        log_info "Alias setup skipped."
    fi
}


verify_fzf_tool


install_tlp_module()            { module_runner "Install TLP" "source \"$BASE_DIR/modules/tlp.sh\"; replace_manager_with_tlp" || log_warn "TLP setup finished with errors."; }
install_apps_module()           { module_runner "Install Apps" "source \"$BASE_DIR/modules/install_apps.sh\"; setup_apps" || log_warn "Apps setup finished with errors."; }
install_yay_module()            { module_runner "Setup yay" "source \"$BASE_DIR/modules/setupyay.sh\"; setup_yay" || log_warn "yay setup finished with errors."; }
install_paru_module()           { module_runner "Setup paru" "source \"$BASE_DIR/modules/setupparu.sh\"; setup_paru" || log_warn "paru setup finished with errors."; }
install_fonts_module()          { module_runner "Install Fonts" "source \"$BASE_DIR/modules/fonts.sh\"; setup_fonts" || log_warn "Fonts setup finished with errors."; }
install_flatpak_module()        { module_runner "Setup Flatpak" "source \"$BASE_DIR/modules/flatpak.sh\"; setup_flatpak" || log_warn "Flatpak setup finished with errors."; }
install_virtualization_module() { module_runner "Setup Virtualization" "source \"$BASE_DIR/modules/setup_virtualization.sh\"; setup_virtualization" || log_warn "Virtualization setup finished with errors."; }
install_shell_module()          { module_runner "Setup Shell" "source \"$BASE_DIR/modules/shell_personalization.sh\"; setup_shell" || log_warn "Shell setup finished with errors."; }
change_desktop_module()         { module_runner "Change Desktop" "source \"$BASE_DIR/modules/change_desktop.sh\"; prompt_change_desktop" || log_warn "Desktop setup finished with errors."; }
setup_gaming_module()           { module_runner "Setup Gaming" "source \"$BASE_DIR/modules/setup_gaming.sh\"; setup_gaming" || log_warn "Gaming setup finished with errors."; }
bluetooth_module()              { module_runner "Setup Bluetooth" "source \"$BASE_DIR/modules/setup_bluetooth.sh\"; setup_bluetooth" || log_warn "Bluetooth setup finished with errors."; }
setup_printer_module()          { module_runner "Setup Printer" "source \"$BASE_DIR/modules/setup_printer.sh\"; setup_printer" || log_warn "Printer setup finished with errors."; }
dsxswap_module()                { module_runner "DSXSWAP" "source \"$BASE_DIR/modules/dsxswap.sh\"; main" || log_warn "Swap configuration finished with errors."; }
setup_drivers_module()          { module_runner "Setup Drivers" "source \"$BASE_DIR/modules/drivers.sh\"; setup_drivers" || log_warn "Driver setup finished with errors."; }
sober_optimization_module()     { module_runner "Sober Optimization" "source \"$BASE_DIR/modules/sober_optimization.sh\"; install" || log_warn "Sober optimization finished with errors."; }
setup_maintenance_module()      { module_runner "System Maintenance" "source \"$BASE_DIR/modules/maintenance.sh\"; system_maintenance" || log_warn "Maintenance tasks finished with errors."; }
setup_fastfetch_module()        { module_runner "Setup Fastfetch" "source \"$BASE_DIR/modules/fastfetch.sh\"; setup_fastfetch" || log_warn "Fastfetch setup finished with errors."; }
setup_multimedia_module()       { module_runner "Setup Multimedia" "source \"$BASE_DIR/modules/multimedia.sh\"; install_multimedia" || log_warn "Multimedia setup finished with errors."; }

BANNER=$(cat <<'EOF'
  ██████╗ ███████╗██╗  ██╗████████╗ ██████╗  ██████╗ ██╗
  ██╔══██╗██╔════╝╚██╗██╔╝╚══██╔══╝██╔═══██╗██╔═══██╗██║
  ██║  ██║███████╗ ╚███╔╝    ██║   ██║   ██║██║   ██║██║
  ██║  ██║╚════██║ ██╔██╗    ██║   ██║   ██║██║   ██║██║
  ██████╔╝███████║██╔╝ ██╗   ██║   ╚██████╔╝╚██████╔╝███████╗
  ╚═════╝ ╚══════╝╚═╝  ╚═╝   ╚═╝    ╚═════╝  ╚═════╝ ╚══════╝
EOF
)


build_menu() {
    printf '%s\n' \
        "1 - Setup Alias" \
        "2 - Install TLP" \
        "3 - Install Apps" \
        "4 - Change Desktop Environment" \
        "5 - Fonts Downloader" \
        "6 - Setup Flatpak" \
        "7 - Setup Virtualization" \
        "8 - Setup Shell" \
        "9 - Setup Gaming" \
        "10 - Setup Bluetooth" \
        "11 - Setup Printer" \
        "12 - DSXSWAP (BETA)" \
        "13 - Sober Optimization" \
        "14 - Setup Drivers" \
        "15 - System Maintenance" \
        "16 - Setup Fastfetch" \
        "17 - Setup Multimedia"

    if [[ "$DISTRO" == "arch" ]]; then
        echo "18 - Setup yay (AUR helper)"
        echo "19 - Setup paru (AUR helper)"
    fi
    echo "0 - Exit"
}

run_menu() {
    local tmp_in tmp_out
    tmp_in=$(mktemp)
    tmp_out=$(mktemp)

    local USER_NAME CURRENT_DE
    USER_NAME="${SUDO_USER:-$USER}"
    CURRENT_DE="${XDG_CURRENT_DESKTOP:-${DESKTOP_SESSION:-unknown}}"
    CURRENT_DE="${CURRENT_DE%%:*}"

    build_menu > "$tmp_in"

    local FZF_COLORS="bg:#121212,bg+:#1e1e1e,fg:#d1d1d1,fg+:#ffffff,hl:#89b4fa,hl+:#89b4fa,prompt:#cba6f7,pointer:#f38ba8,marker:#a6e3a1,header:#e8e8e8,border:#313244"

    SHELL=/usr/bin/bash fzf \
        --layout=reverse \
        --prompt="  ➜  " \
        --color="$FZF_COLORS" \
        --header="$BANNER

  welcome: $USER_NAME
  distro:  $DISTRO
  desktop: $CURRENT_DE
  ─────────────────────────────────────────────
  Type to search, Enter to select, Ctrl-C to cancel.
  Use arrows to move, type to filter, Enter to select." \
        --preview="bash '$BASE_DIR/core/preview.sh' \"\$(echo {} | sed 's/^[0-9]\\+ *- *//')\"" \
        --preview-window=right:50%:wrap,border-left \
        --height=100% \
        --border=rounded \
        --pointer="▶" \
        --info=inline \
        --cycle \
        --bind='ctrl-d:preview-down,ctrl-u:preview-up' \
        < "$tmp_in" > "$tmp_out" || true

    cat "$tmp_out"
    rm -f "$tmp_in" "$tmp_out"
}
dsxtool_main() {
    while true; do
        clear

        local choice
        choice=$(run_menu)

        [[ -z "$choice" ]] && continue

        local item
        item="$(sed 's/^[0-9]\+ *- *//' <<< "$choice")"

        case "$item" in
            "Setup Alias")                 clear; setup_alias ;;
            "Install TLP")                 clear; install_tlp_module ;;
            "Install Apps")                clear; install_apps_module ;;
            "Change Desktop Environment")  clear; change_desktop_module ;;
            "Fonts Downloader")            clear; install_fonts_module ;;
            "Setup Flatpak")               clear; install_flatpak_module ;;
            "Setup Virtualization")        clear; install_virtualization_module ;;
            "Setup Shell")                 clear; install_shell_module ;;
            "Setup Gaming")                clear; setup_gaming_module ;;
            "DSXSWAP (BETA)")              clear; dsxswap_module ;;
            "Setup Bluetooth")             clear; bluetooth_module ;;
            "Setup Printer")               clear; setup_printer_module ;;
            "Setup yay (AUR helper)")      clear; install_yay_module ;;
            "Setup paru (AUR helper)")     clear; install_paru_module ;;
            "Sober Optimization")          clear; sober_optimization_module ;;
            "Setup Drivers")               clear; setup_drivers_module ;;
            "System Maintenance")          clear; setup_maintenance_module ;;
            "Setup Fastfetch")             clear; setup_fastfetch_module ;;
            "Setup Multimedia")            clear; setup_multimedia_module ;;
            "Exit")                        log_info "Exiting"; exit 0 ;;
            *)                             continue ;;
        esac

        prompt_continue
    done
}

dsxtool_main