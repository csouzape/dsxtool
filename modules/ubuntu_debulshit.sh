#!/usr/bin/env bash
set -euo pipefail
# Ubuntu Debullshit
# Strips Ubuntu's default bloat, Snap/telemetry cruft, and vendor add-ons.
# Debian/Ubuntu only — leaves the base system otherwise untouched.

setup_ubuntu_debulshit(){
    if [[ "$DISTRO" != "ubuntu" ]]; then
        log_info "Ubuntu Debullshit is only for Ubuntu-based systems."
        return 0
    fi
    require_sudo
    local repo_url="https://github.com/csouzape/ubuntu-debullshit.git"
    local clone_dir
    clone_dir=$(mktemp -d)
    cleanup(){ rm -rf "${clone_dir:-}" || true; }
    trap cleanup EXIT
    if command -v git &>/dev/null; then
        log_info "git found"
    else
        read -rp "git not found. Install it now? (y/n): " confirm
        [[ "$confirm" =~ ^[Yy]$ ]] || die "git is required to continue."
        log_info "Installing git"
        pkg_install git || die "Failed to install git."
    fi

    log_info "Cloning Ubuntu Debullshit..."
    git clone --depth 1 "$repo_url" "$clone_dir" || die "Failed to clone $repo_url."

    if [[ ! -f "$clone_dir/install.sh" ]]; then
        die "install.sh not found in $repo_url."
    fi

    chmod +x "$clone_dir/install.sh"

    log_info "Running Ubuntu Debullshit..."
    if ! bash "$clone_dir/install.sh"; then
        die "Ubuntu Debullshit script failed."
    fi
    log_success "Ubuntu Debullshit completed successfully."

}
