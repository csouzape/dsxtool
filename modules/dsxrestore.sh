#!/usr/bin/env bash

# modules/dsxrestore.sh
# Intelligent backup/restore manager for dotfiles, configs, and other important files.
# Features planned:
# - Backup and restore functionality for dotfiles and configs.
# - Intelligent detection of changes in dotfiles and configs.
# - Integration with version control systems (e.g., Git) for tracking changes.
# - App snapshot 
    # restore functionality for installed applications and their configurations.




check_dependencies() {
    local dependencies=("git" "unzip" "tar")
    local dep

    for dep in "${dependencies[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            if ask_yn "Dependency '$dep' is not installed. Install now?"; then
                pkg_install "$dep" || return 1
            else
                log_error "Missing dependency: $dep"
                return 1
            fi
        fi
    done

    return 0
}

check_all_dir() {
    local -a dirs=(
        "$HOME/.config"
        "$HOME/.local/share"
        "$HOME/.local/state"
        "$HOME/.cache"
        "$HOME/.bashrc"
        "$HOME/.bash_profile"
        "$HOME/.zshrc"
        "$HOME/.zprofile"
        "$HOME/.profile"
        "$HOME/.tmux.conf"
        "$HOME/.gitconfig"
        "$HOME/.ssh"
        "$HOME/.gnupg"
        "$HOME/.config/Code/User"
        "$HOME/.config/Code - OSS/User"
        "$HOME/.config/gtk-3.0"
        "$HOME/.config/gtk-4.0"
        "$HOME/.config/fish"
        "$HOME/.config/nvim"
        "$HOME/.config/fastfetch"
        "$HOME/.config/paru"
        "$HOME/.config/yay"
        "$HOME/.icons"
        "$HOME/.themes"
        "$HOME/.local/bin"
        "$HOME/Desktop"
        "$HOME/Documents"
        "$HOME/Downloads"
        "$HOME/Pictures"
        "$HOME/Videos"
        "$HOME/Music"
    )

    printf '%s\n' "${dirs[@]}"
}


backup_items() {
    local backup_file="${1:-$HOME/.config/dsxtool/backup_items.txt}"
    local -a items=()
    local item
    local selected

    mkdir -p "$(dirname "$backup_file")"

    while IFS= read -r item; do
        [[ -z "$item" ]] && continue
        [[ -e "$item" ]] && items+=("$item")
    done < <(check_all_dir)

    if [[ ${#items[@]} -eq 0 ]]; then
        log_warn "No valid backup items were found."
        return 1
    fi

    selected=$(printf '%s\n' "${items[@]}" | fzf \
        --multi \
        --layout=reverse \
        --height=80% \
        --border=rounded \
        --prompt='Select backup paths > ' \
        --pointer='▶' \
        --marker='✓' \
        --no-info)

    if [[ -z "$selected" ]]; then
        log_info "No backup paths selected."
        return 1
    fi

    printf '%s\n' "$selected" > "$backup_file"
    log_info "Backup list saved to: $backup_file"

    printf '%s\n' "$selected"
}

backup_items_to_file() {
    local backup_file="${1:-$HOME/.config/dsxtool/backup_items.txt}"
    local -a items=()
    local item

    mkdir -p "$(dirname "$backup_file")"

    while IFS= read -r item; do
        [[ -z "$item" ]] && continue
        [[ -e "$item" ]] && items+=("$item")
    done < <(check_all_dir)

    if [[ ${#items[@]} -eq 0 ]]; then
        log_warn "No valid backup items were found."
        return 1
    fi

    printf '%s\n' "${items[@]}" > "$backup_file"
    log_info "Backup list saved to: $backup_file"
}


backup_menu() {
    check_dependencies || return 1
}