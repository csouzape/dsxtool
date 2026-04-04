#!/usr/bin/env bash
set -euo pipefail

DSXCONFIG_DIR="$HOME/.local/share/dsxconfig"
DSXCONFIG_REPO="https://github.com/csouzape/dsxconfig.git"

_dsxconfig_check_python() {
    if command -v python3 &>/dev/null; then
        log_info "Python3 found."
        return 0
    fi

    log_info "Python3 not found. Installing..."

    case "$DISTRO" in
        arch)   pkg_install python ;;
        debian) pkg_install python3 ;;
        fedora) pkg_install python3 ;;
        *)      die "Unsupported distro for Python3 installation: $DISTRO" ;;
    esac

    if ! command -v python3 &>/dev/null; then
        die "Python3 installation failed. Please install Python3 manually."
    fi

    log_info "Python3 installed successfully."
}

_dsxconfig_install_or_update() {
    if [[ -d "$DSXCONFIG_DIR/.git" ]]; then
        log_info "Updating dsxconfig..."
        git -C "$DSXCONFIG_DIR" fetch origin \
            || die "Failed to fetch dsxconfig updates."
        git -C "$DSXCONFIG_DIR" checkout testing \
            || die "Failed to checkout dsxconfig testing branch."
        git -C "$DSXCONFIG_DIR" pull --ff-only origin testing \
            || die "Failed to update dsxconfig (non fast-forward)."
    else
        log_info "Cloning dsxconfig..."
        rm -rf "$DSXCONFIG_DIR"
        git clone -b testing "$DSXCONFIG_REPO" "$DSXCONFIG_DIR" \
            || die "Failed to clone dsxconfig."
    fi
}

_dsxconfig_run() {
    log_info "Launching dsxconfig..."
    python3 "$DSXCONFIG_DIR/main.py" < /dev/tty
}

setup_dsxconfig() {
    _dsxconfig_check_python
    _dsxconfig_install_or_update
    _dsxconfig_run
}