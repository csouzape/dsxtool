#!/usr/bin/env bash
set -euo pipefail

source "$BASE_DIR/core/common.sh"

declare -A font_pkgs_fedora=(
    [jetbrains-mono]="jetbrains-mono-fonts"
    [fira-code]="fira-code-fonts"
    [source-code-pro]="source-code-pro-fonts"
    [hack]="source-foundry-hack-fonts"
    [cascadia-mono]="cascadia-mono-fonts"
    [iosevka]="iosevka-fonts"
    [monoid]="monoid-fonts"
    [ubuntu-mono]="ubuntu-fonts-mono"
    [dejavu-mono]="dejavu-sans-mono-fonts"
    [meslo]="meslo-nerd-font"  
)

declare -A font_pkgs_debian=(
    [jetbrains-mono]="fonts-jetbrains-mono"
    [fira-code]="fonts-firacode"
    [source-code-pro]="fonts-adobe-sourcecode"   
    [hack]="fonts-hack"
    [cascadia-mono]="fonts-cascadia-code"
    [iosevka]="fonts-iosevka"                    
    [monoid]="fonts-monoid"                      
    [ubuntu-mono]="fonts-ubuntu"
    [dejavu-mono]="fonts-dejavu"
    [meslo]="meslo-nerd-font"                   
)

declare -A font_pkgs_arch=(
    [jetbrains-mono]="ttf-jetbrains-mono"
    [fira-code]="ttf-fira-code"
    [source-code-pro]="adobe-source-code-pro-fonts"
    [hack]="ttf-hack"
    [cascadia-mono]="ttf-cascadia-code"
    [iosevka]="ttf-iosevka"
    [monoid]="ttf-monoid"
    [ubuntu-mono]="ttf-ubuntu-font-family"
    [dejavu-mono]="ttf-dejavu"
    [meslo]="ttf-meslo-nerd-font-powerlevel10k" 
)

detect_distro_family() {
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        case "${ID_LIKE:-$ID}" in
            *fedora*|*rhel*|*centos*) echo "fedora" ;;
            *debian*|*ubuntu*)        echo "debian" ;;
            *arch*)                   echo "arch"   ;;
            *)                        echo "unknown" ;;
        esac
    else
        echo "unknown"
    fi
}

get_font_pkg() {
    local key="$1"
    local distro
    distro=$(detect_distro_family)

    case "$distro" in
        fedora) echo "${font_pkgs_fedora[$key]:-}" ;;
        debian) echo "${font_pkgs_debian[$key]:-}" ;;
        arch)   echo "${font_pkgs_arch[$key]:-}"   ;;
        *)
            log_warn "Distro não reconhecida. Tentando nome genérico."
            echo "$key"
            ;;
    esac
}

install_meslo() {
    local FONT_NAME="MesloLGS NF"
    local FONT_DIR="$HOME/.local/share/fonts/$FONT_NAME"

    if fc-list :family | grep -iq "$FONT_NAME"; then
        log_info "Meslo Nerd Font já instalada."
        return 0
    fi

    if ! command -v git &>/dev/null; then
        log_warn "Git não encontrado."
        read -rp "Instalar git? (y/n): " confirm
        [[ "$confirm" =~ ^[Yy]$ ]] && pkg_install git || return 1
    fi

    log_info "Instalando '$FONT_NAME'..."

    local TEMP_DIR
    TEMP_DIR=$(mktemp -d)
    trap 'rm -rf "$TEMP_DIR"' EXIT

    curl -sSLo "$TEMP_DIR/$FONT_NAME.zip" \
        "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.zip"
    unzip -q "$TEMP_DIR/$FONT_NAME.zip" -d "$TEMP_DIR"
    mkdir -p "$FONT_DIR"
    mv "$TEMP_DIR"/*.ttf "$FONT_DIR"
    fc-cache -f

    log_info "'$FONT_NAME' instalada com sucesso."
}

setup_fonts() {
    local keys=("${!font_pkgs_fedora[@]}")  
    local selected

    selected=$(printf '%s\n' "${keys[@]}" | sort | fzf \
        --prompt="Escolha uma fonte: " \
        --height=40% \
        --border \
        --ansi)

    if [[ -z "$selected" ]]; then
        log_warn "Nenhuma fonte selecionada."
        return 0
    fi

    if [[ "$selected" == "meslo" ]]; then
        install_meslo
        return
    fi

    local pkg
    pkg=$(get_font_pkg "$selected")

    if [[ -z "$pkg" ]]; then
        log_warn "Pacote para '$selected' não mapeado nesta distro. Instalação manual necessária."
        return 1
    fi

    log_info "Instalando '$pkg'..."
    pkg_install "$pkg"
}