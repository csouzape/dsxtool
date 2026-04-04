#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RESET='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${RESET} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${RESET} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${RESET} $*"
}

die() {
    log_error "$*"
    exit 1
}

require_sudo() {
    if [[ $EUID -ne 0 ]] && ! sudo -n true 2>/dev/null; then
        die "This command requires root privileges or passwordless sudo."
    fi
}

prompt_continue() {
    read -rp "$(echo -e "${YELLOW}Press Enter to continue...${RESET}")" < /dev/tty
}
