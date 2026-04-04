#!/usr/bin/env bash
set -euo pipefail

_require_fzf() {
    if ! command -v fzf &>/dev/null; then
        log_error "fzf não encontrado. Instale com: sudo pacman -S fzf  ou  sudo apt install fzf"
        return 1
    fi
}

_fzf_confirm() {
    local prompt="${1:-Confirmar?}"
    local choice
    choice=$(printf "Sim\nNão" \
        | fzf --prompt="$prompt > " \
              --height=5 \
              --layout=reverse \
              --border=rounded \
              --no-info \
              --color='prompt:#61afef,pointer:#e06c75' \
        || true)
    [[ "$choice" == "Sim" ]]
}

_install_desktop() {
    local name="$1"
    local key="$2"
    local pkg
    local -a packages
    pkg=$(get_desktop_packages "$key")
    read -r -a packages <<< "$pkg"
    log_info "Instalando $name (pacotes: $pkg)..."
    _fzf_confirm "Prosseguir com a instalação do $name?" \
        || { log_warn "Instalação cancelada."; return 0; }
    pkg_install "${packages[@]}" \
        && log_info "$name instalado com sucesso." \
        || die "Falha na instalação do $name."
}

install_kde()      { _install_desktop "KDE Plasma" "kde"; }
install_xfce()     { _install_desktop "XFCE" "xfce"; }
install_hyprland() { _install_desktop "Hyprland" "hyprland"; }
install_cosmic()   { _install_desktop "Cosmic" "cosmic"; }

install_hyprland_csouzape() {
    local repo_url="https://github.com/csouzape/hyprdots"

    log_info "Instalando Hyprland (csouzape edition)..."
    _fzf_confirm "Prosseguir com a instalação do Hyprland csouzape edition?" \
        || { log_warn "Instalação cancelada."; return 0; }

    if ! command -v git &>/dev/null; then
        die "Git não está instalado."
    fi

    local tmp_dir
    tmp_dir=$(mktemp -d)

    log_info "Clonando $repo_url..."
    git clone "$repo_url" "$tmp_dir" || {
        rm -rf "$tmp_dir"
        die "Falha ao clonar repositório."
    }

    chmod +x "$tmp_dir/hyprdots.sh"

    if ! sudo bash "$tmp_dir/hyprdots.sh" < /dev/tty; then
        rm -rf "$tmp_dir"
        log_warn "hyprdots.sh encerrou com erro ou foi cancelado."
        return 1
    fi

    rm -rf "$tmp_dir"
    log_info "Config Hyprland do csouzape instalada com sucesso."
}

prompt_change_desktop() {
    _require_fzf || return 1

    local -A actions=(
        ["󰧨  KDE Plasma"]="install_kde"
        ["  XFCE"]="install_xfce"
        ["  Hyprland"]="install_hyprland"
        ["  Hyprland (csouzape edition)"]="install_hyprland_csouzape"
        ["  Cosmic"]="install_cosmic"
        ["  Sair"]="__exit__"
    )

    local options=(
        "  KDE Plasma"
        "  XFCE"
        "  Hyprland"
        "  Hyprland (csouzape edition)"
        "  Cosmic"
        "  Sair"
    )

    local selected
    selected=$(printf '%s\n' "${options[@]}" \
        | fzf --prompt="Ambiente de Desktop > " \
              --header="Selecione o DE para instalar" \
              --height=13 \
              --layout=reverse \
              --border=rounded \
              --pointer="▶" \
              --color='header:#e5c07b,prompt:#61afef,pointer:#e06c75,hl:#98c379' \
              --no-info \
        || true)

    [[ -z "$selected" ]] && { log_warn "Nenhuma opção selecionada."; return 0; }

    local fn="${actions[$selected]}"
    [[ "$fn" == "__exit__" ]] && { log_info "Saindo."; return 0; }

    "$fn"
}