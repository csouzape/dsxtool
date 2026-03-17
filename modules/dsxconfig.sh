#!/usr/bin/env bash
set -uo pipefail

DSXCONFIG_DIR="$HOME/.local/share/dsxconfig"
DSXCONFIG_REPO="https://github.com/csouzape/dsxconfig.git"

_dsxconfig_check_go() {
    if command -v go &>/dev/null; then
        log_info "Go $(go version | awk '{print $3}') found."
        return 0
    fi

    log_info "Go not found. Installing..."

    case "$DISTRO" in
        arch)   pkg_install go ;;
        debian) pkg_install golang-go ;;
        fedora) pkg_install golang ;;
        *)      die "Unsupported distro for Go installation: $DISTRO" ;;
    esac

    if ! command -v go &>/dev/null; then
        die "Go installation failed. Please install Go manually: https://go.dev/dl/"
    fi

    # Verify minimum version (1.21)
    local go_version
    go_version=$(go version | awk '{print $3}' | sed 's/go//')
    local major minor
    major=$(echo "$go_version" | cut -d. -f1)
    minor=$(echo "$go_version" | cut -d. -f2)

    if [[ "$major" -lt 1 ]] || [[ "$major" -eq 1 && "$minor" -lt 21 ]]; then
        log_warn "Go $go_version is too old (minimum: 1.21)."
        log_warn "Please update Go manually: https://go.dev/dl/"
        die "Go version too old."
    fi

    log_info "Go $go_version installed successfully."
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