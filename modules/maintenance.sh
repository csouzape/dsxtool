#!/usr/bin/env bash
set -uo pipefail

_fzf_menu() {
    local tmp_in tmp_out
    tmp_in=$(mktemp)
    tmp_out=$(mktemp)
    cat > "$tmp_in"
    fzf "$@" < "$tmp_in" > "$tmp_out" || true
    cat "$tmp_out"
    rm -f "$tmp_in" "$tmp_out"
}

pkg_clean_cache() {
    log_info "Cleaning package cache..."
    case "$DISTRO" in
        arch)
            if command -v paccache &>/dev/null; then
                sudo paccache -rk1
            else
                sudo pacman -Sc --noconfirm
            fi
            ;;
        debian)
            sudo apt clean
            sudo apt autoclean -y
            ;;
        fedora)
            sudo dnf clean all
            ;;
        *)
            log_warn "Unsupported distro for cache cleaning."
            ;;
    esac
}

pkg_remove_orphans() {
    log_info "Removing orphan packages..."
    case "$DISTRO" in
        arch)
            local orphans
            orphans=$(pacman -Qtdq || true)
            if [[ -n "$orphans" ]]; then
                sudo pacman -Rns $orphans --noconfirm
            else
                log_info "No orphan packages found."
            fi
            ;;
        debian)
            sudo apt autoremove --purge -y
            ;;
        fedora)
            sudo dnf autoremove -y
            ;;
        *)
            log_warn "Unsupported distro for orphan removal."
            ;;
    esac
}

clean_journal() {
    log_info "Vacuuming systemd journal (keeping last 2 weeks)..."
    sudo journalctl --vacuum-time=2weeks
}

clean_user_cache() {
    log_info "Cleaning user cache (~/.cache)..."
    rm -rf "${HOME:?}/.cache/"* 2>/dev/null || true
    log_info "User cache cleaned."
}

trim_ssd() {
    log_info "Running fstrim on all mounted filesystems..."
    sudo fstrim -av
}

clean_flatpak() {
    if ! command -v flatpak &>/dev/null; then
        log_warn "Flatpak not installed. Skipping."
        return 0
    fi
    log_info "Removing unused Flatpak runtimes..."
    flatpak uninstall --unused -y
}

check_failed_services() {
    log_info "Checking for failed systemd services..."
    systemctl --failed --no-pager
}


BANNER=$(cat <<'EOF'
███╗   ███╗ █████╗ ██╗███╗   ██╗████████╗███████╗███╗   ██╗ █████╗ ███╗   ██╗ ██████╗███████╗
████╗ ████║██╔══██╗██║████╗  ██║╚══██╔══╝██╔════╝████╗  ██║██╔══██╗████╗  ██║██╔════╝██╔════╝
██╔████╔██║███████║██║██╔██╗ ██║   ██║   █████╗  ██╔██╗ ██║███████║██╔██╗ ██║██║     █████╗  
██║╚██╔╝██║██╔══██║██║██║╚██╗██║   ██║   ██╔══╝  ██║╚██╗██║██╔══██║██║╚██╗██║██║     ██╔══╝  
██║ ╚═╝ ██║██║  ██║██║██║ ╚████║   ██║   ███████╗██║ ╚████║██║  ██║██║ ╚████║╚██████╗███████╗
╚═╝     ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝   ╚═╝   ╚══════╝╚═╝  ╚═══╝╚═╝  ╚═╝╚═╝  ╚═══╝ ╚═════╝╚══════╝
                                                                                             
EOF
)

system_maintenance() {
    while true; do
        clear

        local selections
        local fzf_header
        fzf_header="$BANNER\n\n[TAB] Select  [ENTER] Run  [ESC] Back"

        selections=$(printf '%s\n' \
            "1 - Update System" \
            "2 - Clean Package Cache" \
            "3 - Remove Orphan Packages" \
            "4 - Clean Journal Logs" \
            "5 - Clean User Cache" \
            "6 - Trim SSD" \
            "7 - Clean Unused Flatpaks" \
            "8 - Check Failed Services" \
            "9 - Exit" \
            | _fzf_menu -m \
                  --ansi \
                  --prompt="Maintenance > " \
                  --header="$fzf_header" \
                  --height=18 \
                  --layout=reverse \
                  --border=rounded \
                  --pointer="▶" \
                  --marker="✓" \
                  --color="bg:#121212,bg+:#1e1e1e,fg:#d1d1d1,fg+:#ffffff,hl:#89b4fa,prompt:#cba6f7,pointer:#f38ba8,marker:#a6e3a1,header:#f9e2af,border:#2a2a2a" \
                  --no-info)

        [[ -z "$selections" ]] && return 0

        while read -r task; do
            [[ -z "$task" ]] && continue
            case "$task" in
                "1 - Update System")          pkg_update ;;
                "2 - Clean Package Cache")    pkg_clean_cache ;;
                "3 - Remove Orphan Packages") pkg_remove_orphans ;;
                "4 - Clean Journal Logs")     clean_journal ;;
                "5 - Clean User Cache")       clean_user_cache ;;
                "6 - Trim SSD")               trim_ssd ;;
                "7 - Clean Unused Flatpaks")  clean_flatpak ;;
                "8 - Check Failed Services")  check_failed_services ;;
                "9 - Exit"|"exit")            log_info "Exiting"; exit 0 ;;
                *)                         log_warn "Unknown task: $task" ;;
            esac
        done <<< "$selections"

        log_info "Maintenance completed."
        prompt_continue
    done
}
