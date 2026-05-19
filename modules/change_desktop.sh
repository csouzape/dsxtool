#!/usr/bin/env bash
set -euo pipefail

_require_fzf() {
    if command -v fzf &>/dev/null; then
        return 0
    fi

    log_warn "fzf não encontrado. Será usado um menu de texto simples."
    return 1
}

_select_desktop_option() {
    local options=()
    local option
    local selected

    options+=("$@")

    if command -v fzf &>/dev/null; then
        selected=$(printf '%s\n' "${options[@]}" \
            | fzf --prompt="Ambiente de Desktop > " \
                  --header="Selecione o DE para instalar" \
                  --height=20 \
                  --layout=reverse \
                  --border=rounded \
                  --pointer="▶" \
                  --color='header:#e5c07b,prompt:#61afef,pointer:#e06c75,hl:#98c379' \
                  --no-info \
            || true)
        printf '%s' "$selected"
        return
    fi

    echo "Escolha o ambiente pelo número:" >&2
    PS3='Ambiente de Desktop > '
    select option in "${options[@]}"; do
        if [[ -n "$option" ]]; then
            printf '%s' "$option"
            return
        fi
        echo "Opção inválida, tente novamente." >&2
    done
}

_resolve_desktop_packages() {
    local key="$1"
    local pkg
    pkg=$(get_desktop_packages "$key")

    if [[ -z "${pkg// }" ]]; then
        die "Não há pacotes mapeados para '$key' em $DISTRO. Verifique se esse ambiente é suportado nesta distro."
    fi

    printf '%s' "$pkg"
}

_fzf_confirm() {
    local prompt="${1:-Confirmar?}"
    local choice

    if command -v fzf &>/dev/null; then
        choice=$(printf "Sim\nNão" \
            | fzf --prompt="$prompt > " \
                  --height=5 \
                  --layout=reverse \
                  --border=rounded \
                  --no-info \
                  --color='prompt:#61afef,pointer:#e06c75' \
            || true)
        [[ "$choice" == "Sim" ]]
        return
    fi

    read -rp "$prompt (s/n): " choice < /dev/tty
    [[ "$choice" =~ ^[Ss]$ ]]
}

_install_desktop() {
    local name="$1"
    local key="$2"
    local pkg
    local packages=()

    pkg=$(_resolve_desktop_packages "$key")
    read -r -a packages <<< "$pkg"

    log_info "Instalando $name (pacotes: $pkg)..."
    _fzf_confirm "Prosseguir com a instalação do $name?" \
        || { log_warn "Instalação cancelada."; return 0; }

    pkg_install "${packages[@]}" \
        && log_info "$name instalado com sucesso." \
        || die "Falha na instalação do $name."
}

install_kde()       { _install_desktop "KDE Plasma"  "kde"; }
install_xfce()      { _install_desktop "XFCE"        "xfce"; }
install_hyprland()  { _install_desktop "Hyprland"    "hyprland"; }
install_cosmic()    { _install_desktop "Cosmic"      "cosmic"; }
install_gnome()     { _install_desktop "GNOME"       "gnome"; }
install_mate()      { _install_desktop "MATE"        "mate"; }
install_cinnamon()  { _install_desktop "Cinnamon"    "cinnamon"; }
install_i3()        { _install_desktop "i3"          "i3"; }
install_sway()      { _install_desktop "Sway"        "sway"; }
install_budgie()    { _install_desktop "Budgie"      "budgie"; }

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
    _require_fzf

    local -A actions=(
        ["󰧨  KDE Plasma"]="install_kde"
        ["  XFCE"]="install_xfce"
        ["  Hyprland"]="install_hyprland"
        ["  Hyprland (csouzape edition)"]="install_hyprland_csouzape"
        ["  Cosmic"]="install_cosmic"
        ["  GNOME"]="install_gnome"
        ["  MATE"]="install_mate"
        ["  Cinnamon"]="install_cinnamon"
        ["  i3"]="install_i3"
        ["  Sway"]="install_sway"
        ["  Budgie"]="install_budgie"
        ["  Sair"]="__exit__"
    )

    local options=(
        "  KDE Plasma"
        "  XFCE"
        "  Hyprland"
        "  Hyprland (csouzape edition)"
        "  Cosmic"
        "  GNOME"
        "  MATE"
        "  Cinnamon"
        "  i3"
        "  Sway"
        "  Budgie"
        "  Sair"
    )

    local selected
    selected=$(_select_desktop_option "${options[@]}")

    [[ -z "$selected" ]] && { log_warn "Nenhuma opção selecionada."; return 0; }

    local fn="${actions[$selected]}"
    [[ "$fn" == "__exit__" ]] && { log_info "Saindo."; return 0; }

    "$fn"
}