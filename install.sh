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

verify_fzf_tool


update_system_module() {
    source "$BASE_DIR/modules/update_system.sh"
    update_system || log_warn "update_system finished with errors."
}

install_tlp_module() {
    source "$BASE_DIR/modules/tlp.sh"
    replace_manager_with_tlp || log_warn "TLP setup finished with errors."
}

install_apps_module() {
    source "$BASE_DIR/modules/install_apps.sh"
    setup_apps || log_warn "Apps setup finished with errors."
}

install_alacritty_module() {
    source "$BASE_DIR/modules/alacritty.sh"
    install_alacritty || log_warn "Alacritty install finished with errors."
}

install_konsole_module() {
    source "$BASE_DIR/modules/konsole.sh"
    setup_konsole || log_warn "Konsole setup finished with errors."
}

install_kitty_module() {
    source "$BASE_DIR/modules/kitty.sh"
    setup_kitty || log_warn "Kitty setup finished with errors."
}

install_ghostty_module() {
    source "$BASE_DIR/modules/ghostty.sh"
    install_ghostty || log_warn "Ghostty install finished with errors."
}

install_wallpapers_module() {
    source "$BASE_DIR/modules/wallpapers.sh"
    prompt_wallpapers || log_warn "Wallpapers setup finished with errors."
}

install_yay_module() {
    source "$BASE_DIR/modules/setupyay.sh"
    setup_yay || log_warn "yay setup finished with errors."
}

install_fonts_module() {
    source "$BASE_DIR/modules/fonts.sh"
    setup_fonts || log_warn "Fonts setup finished with errors."
}

install_flatpak_module() {
    source "$BASE_DIR/modules/flatpak.sh"
    setup_flatpak || log_warn "Flatpak setup finished with errors."
}

install_virtualization_module() {
    source "$BASE_DIR/modules/setup_virtualization.sh"
    setup_virtualization || log_warn "Virtualization setup finished with errors."
}

install_shell_module() {
    source "$BASE_DIR/modules/shell_personalization.sh"
    setup_shell || log_warn "Shell setup finished with errors."
}

change_desktop_module() {
    source "$BASE_DIR/modules/change_desktop.sh"
    prompt_change_desktop || log_warn "Desktop setup finished with errors."
}

setup_gaming_module() {
    source "$BASE_DIR/modules/setup_gaming.sh"
    setup_gaming || log_warn "Gaming setup finished with errors."
}

dsxconfig_module() {
    source "$BASE_DIR/modules/dsxconfig.sh"
    setup_dsxconfig || log_warn "dsxconfig finished with errors."
}



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
        "1 - Update System" \
        "2 - Install TLP" \
        "3 - Install Apps" \
        "4 - Install Alacritty" \
        "5 - Install Konsole" \
        "6 - Install Kitty" \
        "7 - Install Ghostty" \
        "8 - Setup Wallpapers" \
        "9 - Change Desktop Environment" \
        "10 - Fonts Downloader" \
        "11 - Setup Flatpak" \
        "12 - Setup Virtualization" \
        "13 - Setup Shell" \
        "14 - Setup Gaming" \
        "15 - DSXConfig (backup & restore)"

    [[ "$DISTRO" == "arch" ]] && echo "16 - Setup yay (AUR helper)"
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

    fzf \
        --layout=reverse \
        --prompt="  ➜  " \
        --color="bg:#121212,bg+:#1e1e1e,\
fg:#d1d1d1,fg+:#ffffff,\
hl:#89b4fa,hl+:#89b4fa,\
prompt:#cba6f7,\
pointer:#f38ba8,\
marker:#a6e3a1,\
header:#e8e8e8,\
border:#313244" \
        --header="$BANNER

  welcome: $USER_NAME
  distro: $DISTRO
  desktop: $CURRENT_DE
  ─────────────────────────────────────────────" \
        --preview='
item=$(echo {} | sed "s/^[0-9]\+ *- *//")
case "$item" in
"Update System")             echo "Runs a full system package upgrade."; echo; echo "  pacman -Syu (Arch)"; echo "  dnf upgrade (Fedora)"; echo "  apt upgrade (Debian)" ;;
"Install TLP")               echo "Battery & power management for laptops."; echo; echo "  • Replaces power-profiles-daemon"; echo "  • CPU and battery tuning" ;;
"Install Apps")              echo "Install apps by category:"; echo; echo "  Browsers, Media, Communication,"; echo "  Productivity, Gaming, Development" ;;
"Install Alacritty")         echo "GPU-accelerated terminal emulator."; echo; echo "  • Written in Rust"; echo "  • OpenGL rendering" ;;
"Install Konsole")           echo "KDE default terminal emulator."; echo; echo "  • Tabbed interface"; echo "  • Split view support" ;;
"Install Kitty")             echo "Fast feature-rich terminal."; echo; echo "  • GPU rendering"; echo "  • Native image display" ;;
"Install Ghostty")           echo "Modern terminal built for speed."; echo; echo "  • Native platform integration"; echo "  • Built-in multiplexer" ;;
"Setup Wallpapers")          echo "Downloads csouzape wallpaper collection."; echo; echo "  • Saved to ~/Pictures/wallpapers" ;;
"Change Desktop Environment") echo "Install a new desktop environment."; echo; echo "  KDE · XFCE · Hyprland · Cosmic"; echo "  Hyprland csouzape edition" ;;
"Fonts Downloader")          echo "Install curated Nerd Fonts collection."; echo; echo "  • Terminal and IDE icon fonts" ;;
"Setup Flatpak")             echo "Installs Flatpak + Flathub remote."; echo; echo "  • Enables sandboxed app distribution" ;;
"Setup Virtualization")      echo "Installs KVM/QEMU virtualization stack."; echo; echo "  • virt-manager GUI"; echo "  • libvirt + virtnetworkd" ;;
"Setup Shell")               echo "Configure your shell environment."; echo; echo "  • Zsh + oh-my-zsh"; echo "  • Fish + fisher"; echo "  • Plugins and prompt setup" ;;
"Setup Gaming")              echo "Full gaming environment setup."; echo; echo "  • Wine + gaming libraries"; echo "  • Steam + Lutris"; echo "  • MangoHud + GameMode" ;;
"DSXConfig (backup & restore)") echo "Backup and restore your Linux setup."; echo; echo "  • Export packages, AUR, Flatpak"; echo "  • Backup dotfiles"; echo "  • Restore on any machine"; echo "  • Cross-distro support" ;;
"Setup yay (AUR helper)")    echo "Builds and installs yay from AUR."; echo; echo "  • Arch Linux only"; echo "  • Requires non-root user" ;;
"Exit")                      echo "Exit dsxtool." ;;
esac
' \
        --preview-window=right:45%:wrap,border-left \
        --height=100% \
        --border=rounded \
        --pointer="▶" \
        --no-info \
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
            "Update System")                 clear; update_system_module ;;
            "Install TLP")                   clear; install_tlp_module ;;
            "Install Apps")                  clear; install_apps_module ;;
            "Install Alacritty")             clear; install_alacritty_module ;;
            "Install Konsole")               clear; install_konsole_module ;;
            "Install Kitty")                 clear; install_kitty_module ;;
            "Install Ghostty")               clear; install_ghostty_module ;;
            "Setup Wallpapers")              clear; install_wallpapers_module ;;
            "Change Desktop Environment")    clear; change_desktop_module ;;
            "Fonts Downloader")              clear; install_fonts_module ;;
            "Setup Flatpak")                 clear; install_flatpak_module ;;
            "Setup Virtualization")          clear; install_virtualization_module ;;
            "Setup Shell")                   clear; install_shell_module ;;
            "Setup Gaming")                  clear; setup_gaming_module ;;
            "DSXConfig (backup & restore)")  clear; dsxconfig_module ;;
            "Setup yay (AUR helper)")        clear; install_yay_module ;;
            "Exit")                          log_info "Exiting"; exit 0 ;;
            *)                               continue ;;
        esac

        prompt_continue
    done
}

dsxtool_main