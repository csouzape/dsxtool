#!/usr/bin/env bash
set -uo pipefail

DSXCONFIG_DIR="$HOME/.local/share/dsxconfig"
DSXCONFIG_REPO="https://github.com/csouzape/dsxconfig.git"

_dsxconfig_check_go() {
    if command -v go &>/dev/null; then
        return 0
    fi
    log_info "Go not found. Installing..."
    pkg_install go || die "Failed to install Go."
}

_dsxconfig_install_or_update() {
    if [[ -d "$DSXCONFIG_DIR/.git" ]]; then
        log_info "Updating dsxconfig..."
        git -C "$DSXCONFIG_DIR" fetch origin \
            || die "Failed to fetch dsxconfig updates."
        git -C "$DSXCONFIG_DIR" reset --hard origin/main \
            || die "Failed to update dsxconfig."
    else
        log_info "Cloning dsxconfig..."
        rm -rf "$DSXCONFIG_DIR"
        git clone "$DSXCONFIG_REPO" "$DSXCONFIG_DIR" \
            || die "Failed to clone dsxconfig."
    fi
}

_dsxconfig_build() {
    log_info "Building dsxconfig..."
    (cd "$DSXCONFIG_DIR" && go build -o dsxconfig .) \
        || die "Failed to build dsxconfig."
    log_info "dsxconfig built successfully."
}

_dsxconfig_run() {
    log_info "Launching dsxconfig..."
    "$DSXCONFIG_DIR/dsxconfig" < /dev/tty
}

setup_dsxconfig() {
    _dsxconfig_check_go
    _dsxconfig_install_or_update
    _dsxconfig_build
    _dsxconfig_run
}