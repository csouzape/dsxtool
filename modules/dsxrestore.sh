#!/usr/bin/env bash

# modules/dsxrestore.sh
# Intelligent backup/restore manager for dotfiles, configs, and other important files.
# Features planned:
# - Backup and restore functionality for dotfiles and configs.
# - Intelligent detection of changes in dotfiles and configs.
# - Integration with version control systems (e.g., Git) for tracking changes.
# - App snapshot
# - restore functionality for installed applications and their configurations.

check_dependencies() {
    local dependencies=("git" "unzip")
    local missing=()

    for dep in "${dependencies[@]}"; do
        if ! pkg_exists "$dep"; then
            missing+=("$dep")
        fi
    done

    # Nada faltando, segue o fluxo normalmente
    if [[ ${#missing[@]} -eq 0 ]]; then
        log_success "All dependencies are already satisfied."
        return 0
    fi

    log_warn "Missing dependencies: ${missing[*]}"
    read -rp "$(echo -e "${YELLOW}Install them now? [Y/n]${RESET} ")" reply

    if [[ "${reply,,}" =~ ^(n|no)$ ]]; then
        log_error "Cannot continue without: ${missing[*]}"
        return 1
    fi

    for dep in "${missing[@]}"; do
        log_info "Installing $dep..."
        pkg_install "$dep" || die "Failed to install dependency: $dep"
    done

    log_success "All dependencies installed."
    return 0
}