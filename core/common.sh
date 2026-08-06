#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RESET='\033[0m'

# Logging defaults (dsxtool starts a global log session automatically)
LOG_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/dsxtool/logs"
LOG_FILE=""
_LOGGING_ACTIVE=0

on_error() {
    # Called by trap when a command fails (only active if start_logging used)
    local exit_code=${1:-1}
    echo -e "${RED}[ERROR]${RESET} A command failed with exit code ${exit_code}."
    if [[ "$_LOGGING_ACTIVE" -eq 1 && -n "$LOG_FILE" && -f "$LOG_FILE" ]]; then
        read -rp "Would you like to copy the log file to your home directory for inspection? [Y/n]: " ans < /dev/tty || true
        ans="${ans:-y}"
        if [[ "${ans,,}" =~ ^(y|yes)$ ]]; then
            local dest="$HOME/dsxtool-error-$(date +%Y%m%d-%H%M%S).log"
            cp -v -- "$LOG_FILE" "$dest" || echo "Failed to copy log file to $dest"
            echo "Saved logs to: $dest"
        else
            echo "Logs are available at: $LOG_FILE"
        fi
    else
        echo "No log file available. Logging may not have started correctly."
    fi
}

start_logging() {
    mkdir -p "$LOG_DIR"
    LOG_FILE="$LOG_DIR/dsxtool-$(date +%Y%m%d-%H%M%S).log"
    # Redirect stdout/stderr to tee so output still appears on console
    exec > >(tee -a "$LOG_FILE") 2>&1
    _LOGGING_ACTIVE=1
    echo -e "${GREEN}[INFO]${RESET} dsxtool log session started: $LOG_FILE"
    # Install ERR trap to offer saving logs on error
    trap 'on_error $?' ERR
}

is_logging_active() {
    [[ "$_LOGGING_ACTIVE" -eq 1 ]]
}

module_runner() {
    local module="$1"; shift
    local cmd="$*"
    mkdir -p "$LOG_DIR"
    local safe
    safe=$(printf '%s' "$module" | tr ' /' '__' | tr -cd 'A-Za-z0-9_.-')
    local module_log="$LOG_DIR/${safe}_$(date +%Y%m%d-%H%M%S).log"

    echo -e "${GREEN}[MODULE]${RESET} $module - running (capturing output to $module_log)."

    bash -lc "set -o pipefail; source \"$BASE_DIR/core/common.sh\"; source \"$BASE_DIR/core/detect.sh\"; detect_distro; source \"$BASE_DIR/core/distros/$DISTRO.sh\"; $cmd" 2>&1 | tee "$module_log"
    local rc=${PIPESTATUS[0]:-1}

    if [[ $rc -ne 0 ]]; then
        echo -e "${RED}[MODULE ERROR]${RESET} $module failed (exit $rc). Log saved: $module_log"
    else
        echo -e "${GREEN}[MODULE]${RESET} $module completed successfully. Log path: $module_log"
    fi

    return $rc
}

log_info() {
    echo -e "${GREEN}[INFO]${RESET} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${RESET} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${RESET} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${RESET} $*"
}

die() {
    log_error "$*"
    # If logging active, offer immediate copy before exiting
    if is_logging_active; then
        on_error 1
    fi
    exit 1
}

get_aur_helper() {
    if command -v paru >/dev/null 2>&1; then
        printf '%s' "paru"
        return 0
    fi
    if command -v yay >/dev/null 2>&1; then
        printf '%s' "yay"
        return 0
    fi
    return 1
}

require_aur_helper() {
    if ! get_aur_helper >/dev/null 2>&1; then
        die "AUR helper not installed. Please run 'Setup yay' or 'Setup paru' first."
    fi
}

aur_install() {
    local helper
    helper=$(get_aur_helper) || die "AUR helper not installed. Please run 'Setup yay' or 'Setup paru' first."
    sudo -u "${SUDO_USER:-$USER}" "$helper" -S --noconfirm "$@"
}

aur_query() {
    local helper
    helper=$(get_aur_helper) || return 1
    "$helper" -Q "$1" &>/dev/null
}

require_sudo() {
    if [[ $EUID -ne 0 ]] && ! sudo -n true 2>/dev/null; then
        die "This command requires root privileges or passwordless sudo."
    fi
}

_check_not_root() {
    if [[ $EUID -eq 0 ]]; then
        die "$1 cannot be installed as root. Please run dsxtool as a normal user."
    fi
}

prompt_continue() {
    read -rp "$(echo -e "${YELLOW}Press Enter to continue...${RESET}")"
}
