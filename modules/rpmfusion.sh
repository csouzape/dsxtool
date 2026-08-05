#!/usr/bin/env bash
set -uo pipefail

setup_rpmfusion() {
    if [[ "${DISTRO:-}" != "fedora" ]]; then
        log_info "RPM Fusion is only needed on Fedora-based systems. Skipping."
        return 0
    fi

    require_sudo

    local fedora_ver free_url nonfree_url
    fedora_ver=$(rpm -E %fedora 2>/dev/null || true)

    if [[ -z "$fedora_ver" ]]; then
        die "Unable to detect the Fedora release version."
    fi

    free_url="https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${fedora_ver}.noarch.rpm"
    nonfree_url="https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${fedora_ver}.noarch.rpm"

    local packages=()
    if ! rpm -q rpmfusion-free-release >/dev/null 2>&1; then
        packages+=("$free_url")
    fi

    if ! rpm -q rpmfusion-nonfree-release >/dev/null 2>&1; then
        packages+=("$nonfree_url")
    fi

    if [[ ${#packages[@]} -eq 0 ]]; then
        log_info "RPM Fusion repositories are already enabled."
        return 0
    fi

    log_info "Enabling RPM Fusion repositories (free + nonfree)..."
    pkg_install "${packages[@]}" || die "Failed to enable RPM Fusion repositories."
    log_info "RPM Fusion repositories enabled successfully."
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    setup_rpmfusion "$@"
fi
