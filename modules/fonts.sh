#!/usr/bin/env bash
set -euo pipefail

source "$BASE_DIR/core/common.sh"

declare -A FONT_PKG_ARCH
declare -A FONT_PKG_DEBIAN
declare -A FONT_PKG_FEDORA
declare -A FONT_FC_NAME

FONT_PKG_ARCH["JetBrains Mono"]="ttf-jetbrains-mono"
FONT_PKG_ARCH["Fira Code"]="ttf-fira-code"
FONT_PKG_ARCH["Source Code Pro"]="ttf-sourcecodepro-nerd"
FONT_PKG_ARCH["Hack"]="ttf-hack"
FONT_PKG_ARCH["Cascadia Mono"]="ttf-cascadia-mono-nerd"
FONT_PKG_ARCH["Iosevka"]="ttc-iosevka"
FONT_PKG_ARCH["Ubuntu Mono"]="ttf-ubuntu-mono"
FONT_PKG_ARCH["DejaVu Sans Mono"]="ttf-dejavu"
FONT_PKG_ARCH["Meslo Nerd Font"]="ttf-meslo-nerd"

FONT_PKG_DEBIAN["JetBrains Mono"]="fonts-jetbrains-mono"
FONT_PKG_DEBIAN["Fira Code"]="fonts-firacode"
FONT_PKG_DEBIAN["Source Code Pro"]="fonts-adobe-sourcepro"
FONT_PKG_DEBIAN["Hack"]="fonts-hack"
FONT_PKG_DEBIAN["Cascadia Mono"]="native"
FONT_PKG_DEBIAN["Iosevka"]="fonts-iosevka"
FONT_PKG_DEBIAN["Ubuntu Mono"]="fonts-ubuntu"
FONT_PKG_DEBIAN["DejaVu Sans Mono"]="fonts-dejavu"
FONT_PKG_DEBIAN["Meslo Nerd Font"]="native"

FONT_PKG_FEDORA["JetBrains Mono"]="jetbrains-mono-fonts"
FONT_PKG_FEDORA["Fira Code"]="fira-code-fonts"
FONT_PKG_FEDORA["Source Code Pro"]="adobe-source-code-pro-fonts"
FONT_PKG_FEDORA["Hack"]="source-foundry-hack-fonts"
FONT_PKG_FEDORA["Cascadia Mono"]="cascadia-fonts"
FONT_PKG_FEDORA["Iosevka"]="native"
FONT_PKG_FEDORA["Ubuntu Mono"]="ubuntu-mono-fonts"
FONT_PKG_FEDORA["DejaVu Sans Mono"]="dejavu-sans-mono-fonts"
FONT_PKG_FEDORA["Meslo Nerd Font"]="native"

FONT_FC_NAME["JetBrains Mono"]="JetBrains Mono"
FONT_FC_NAME["Fira Code"]="Fira Code"
FONT_FC_NAME["Source Code Pro"]="Source Code Pro"
FONT_FC_NAME["Hack"]="Hack"
FONT_FC_NAME["Cascadia Mono"]="Cascadia Mono"
FONT_FC_NAME["Iosevka"]="Iosevka"
FONT_FC_NAME["Ubuntu Mono"]="Ubuntu Mono"
FONT_FC_NAME["DejaVu Sans Mono"]="DejaVu Sans Mono"
FONT_FC_NAME["Meslo Nerd Font"]="MesloLGS NF"

_is_font_installed() {
    local fc_name="$1"
    fc-list :family 2>/dev/null | grep -iq "$fc_name"
}

_install_font_native() {
    local font="$1"
    local fc_name="${FONT_FC_NAME[$font]}"
    local font_dir="$HOME/.local/share/fonts/$font"

    if _is_font_installed "$fc_name"; then
        log_info "'$font' is already installed."
        return 0
    fi

    if ! command -v git &>/dev/null; then
        log_warn "Git not found."
        read -rp "Install git? (y/n): " confirm < /dev/tty
        [[ "$confirm" =~ ^[Yy]$ ]] && pkg_install git || return 1
    fi

    log_info "Installing '$font' from Nerd Fonts..."

    local tmp_dir
    tmp_dir=$(mktemp -d)
    trap 'rm -rf "$tmp_dir"' EXIT

    local nf_name
    case "$font" in
        "Meslo Nerd Font") nf_name="Meslo" ;;
        "Cascadia Mono")   nf_name="CascadiaMono" ;;
        "Iosevka")         nf_name="Iosevka" ;;
        *)
            die "No native install handler for: $font"
            ;;
    esac

    curl -sSLo "$tmp_dir/$nf_name.zip" \
        "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${nf_name}.zip" \
        || die "Failed to download '$font'."

    unzip -q "$tmp_dir/$nf_name.zip" -d "$tmp_dir"
    mkdir -p "$font_dir"
    find "$tmp_dir" -name "*.ttf" -exec mv {} "$font_dir/" \;
    fc-cache -f

    log_info "'$font' installed successfully."
}

_install_font() {
    local font="$1"
    local fc_name="${FONT_FC_NAME[$font]:-$font}"

    if _is_font_installed "$fc_name"; then
        log_warn "'$font' is already installed."
        read -rp "Remove it? (y/n): " confirm < /dev/tty
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            local font_dir="$HOME/.local/share/fonts/$font"
            rm -rf "$font_dir"
            fc-cache -f
            log_info "'$font' removed."
        else
            log_info "Skipping '$font'."
        fi
        return
    fi

    local pkg=""
    case "$DISTRO" in
        arch)   pkg="${FONT_PKG_ARCH[$font]:-}" ;;
        debian) pkg="${FONT_PKG_DEBIAN[$font]:-}" ;;
        fedora) pkg="${FONT_PKG_FEDORA[$font]:-}" ;;
    esac

    if [[ -z "$pkg" || "$pkg" == "native" ]]; then
        _install_font_native "$font"
    else
        log_info "Installing '$font'..."
        pkg_install "$pkg"
        log_info "'$font' installed successfully."
    fi
}

setup_fonts() {
    local font_list=()
    for font in "${!FONT_FC_NAME[@]}"; do
        font_list+=("$font")
    done

    IFS=$'\n' font_list=($(sort <<< "${font_list[*]}")); unset IFS

    local selected
    selected=$(printf '%s\n' "${font_list[@]}" | fzf \
        --prompt="  Font > " \
        --height=40% \
        --border=rounded \
        --pointer="▶" \
        --layout=reverse \
        --no-info \
        --color="bg:#121212,bg+:#1e1e1e,fg:#d1d1d1,fg+:#ffffff,hl:#89b4fa,prompt:#cba6f7,pointer:#f38ba8,border:#313244") || true

    if [[ -z "$selected" ]]; then
        log_warn "No font selected."
        return 0
    fi

    _install_font "$selected"
}