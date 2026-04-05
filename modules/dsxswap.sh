#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RESET='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${RESET} $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${RESET} $*"; }
log_error() { echo -e "${RED}[ERROR]${RESET} $*"; }

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
    read -rp "$(echo -e "${YELLOW}Press Enter to continue...${RESET}")"
}


require() { command -v "$1" >/dev/null 2>&1 || die "Missing dependency: $1"; }
require fzf
require numfmt


BANNER=$(cat <<'EOF'
  ██████╗ ██╗  ██╗███████╗██╗    ██╗ █████╗ ██████╗ 
  ██╔══██╗╚██╗██╔╝██╔════╝██║    ██║██╔══██╗██╔══██╗
  ██║  ██║ ╚███╔╝ ███████╗██║ █╗ ██║███████║██████╔╝
  ██║  ██║ ██╔██╗ ╚════██║██║███╗██║██╔══██║██╔═══╝ 
  ██████╔╝██╔╝ ██╗███████║╚███╔███╔╝██║  ██║██║     
  ╚═════╝ ╚═╝  ╚═╝╚══════╝ ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝     
EOF
)

fzf_menu() {
    fzf \
        --layout=reverse \
        --height=100% \
        --border=rounded \
        --pointer="▶" \
        --no-info \
        --color="bg:#121212,bg+:#1e1e1e,fg:#d1d1d1,fg+:#ffffff,hl:#89b4fa,hl+:#89b4fa,prompt:#cba6f7,pointer:#f38ba8,marker:#a6e3a1,header:#e8e8e8,border:#313244" \
        --header="$BANNER
  ─────────────────────────────────────────────" \
        --prompt="  ➜  " \
        "$@"
}

print_swap_info() {
    if [ -f /proc/swaps ]; then
        awk 'NR>1 {printf "Swap: %s | Type: %s | Size: %s KB\n", $1, $2, $3}' /proc/swaps
    else
        log_warn "No active swap found."
    fi
}

is_arch() { [ -f /etc/arch-release ]; }

has_zram_generator() {
    command -v zramctl >/dev/null 2>&1 && {
        (command -v pacman >/dev/null 2>&1 && pacman -Q zram-generator >/dev/null 2>&1) ||
        [ -f /usr/lib/systemd/system-generators/zram-generator ]
    }
}

size_to_mib() {
    numfmt --from=iec --to-unit=1M "$1"
}

menu_main() {
    printf "%s\n" \
        "Configure swap" \
        "View current swap" \
        "Quit" \
    | fzf_menu --prompt="Swap > "
}

choose_type() {
    printf "%s\n" "swapfile" "zram" "zswap" "Cancel" \
    | fzf_menu --prompt="Type: "
}

choose_zram_method() {
    printf "%s\n" "zram-generator" "manual (modprobe)" "Cancel" \
    | fzf_menu --prompt="ZRAM method: "
}

choose_size() {
    printf "%s\n" "512M" "1G" "2G" "4G" "8G" "16G" "Cancel" \
    | fzf_menu --prompt="Size: "
}

choose_swappiness() {
    printf "%s\n" "10" "20" "40" "60" "80" "100" "Cancel" \
    | fzf_menu --prompt="Swappiness (kernel default: 60): "
}

apply_swappiness() {
    local v="$1"
    log_info "Setting vm.swappiness to $v..."
    sudo sysctl -q vm.swappiness="$v"
    echo "vm.swappiness=$v" | sudo tee /etc/sysctl.d/99-swappiness.conf >/dev/null
    log_info "Swappiness persisted to /etc/sysctl.d/99-swappiness.conf."
}

setup_swapfile() {
    local size="$1" file="/swapfile"
    log_info "Setting up swapfile at $file ($size)..."
    sudo swapoff "$file" 2>/dev/null && log_warn "Previous swapfile deactivated." || true
    sudo rm -f "$file"
    sudo fallocate -l "$size" "$file"
    sudo chmod 600 "$file"
    sudo mkswap "$file"
    sudo swapon "$file"
    log_info "Swapfile active: $file ($size)."
}

setup_zram_generator() {
    local size_mib
    size_mib=$(size_to_mib "$1")
    log_info "Configuring ZRAM via zram-generator (${size_mib} MiB)..."
    sudo mkdir -p /etc/systemd/zram-generator.conf.d
    sudo tee /etc/systemd/zram-generator.conf.d/zram.conf >/dev/null <<EOF
[zram0]
zram-size = ${size_mib}
compression-algorithm = zstd
EOF
    sudo systemctl daemon-reload
    sudo systemctl restart systemd-zram-setup@zram0.service || \
        log_warn "Could not restart zram unit — a reboot may be required."
    log_info "ZRAM configured via zram-generator."
}

setup_zram_manual() {
    local size="$1"
    local bytes
    bytes=$(numfmt --from=iec "$size")
    log_info "Configuring ZRAM manually ($size = $bytes bytes)..."
    if grep -q /dev/zram0 /proc/swaps 2>/dev/null; then
        log_warn "Deactivating existing /dev/zram0..."
        sudo swapoff /dev/zram0
    fi
    sudo modprobe zram
    echo "$bytes" | sudo tee /sys/block/zram0/disksize >/dev/null
    sudo mkswap /dev/zram0
    sudo swapon /dev/zram0
    log_info "ZRAM active: /dev/zram0 ($size)."
}

setup_zram() {
    local size="$1"
    if is_arch && has_zram_generator; then
        local m
        m=$(choose_zram_method)
        [[ "$m" == "Cancel" || -z "$m" ]] && return
        case "$m" in
            "zram-generator")    setup_zram_generator "$size" ;;
            "manual (modprobe)") setup_zram_manual "$size" ;;
        esac
    else
        log_info "zram-generator not available — falling back to manual setup."
        setup_zram_manual "$size"
    fi
}

setup_zswap() {
    local size="$1"
    log_info "Loading zswap kernel module..."
    sudo modprobe zswap || log_warn "modprobe zswap failed — may already be built-in."
    echo 1 | sudo tee /sys/module/zswap/parameters/enabled >/dev/null
    log_info "zswap enabled. Setting up backing swapfile ($size)..."
    setup_swapfile "$size"
    log_info "zswap active with $size swapfile as backing store."
}


configure_swap() {
    local type size swp

    type=$(choose_type)
    [[ "$type" == "Cancel" || -z "$type" ]] && return

    size=$(choose_size)
    [[ "$size" == "Cancel" || -z "$size" ]] && return

    swp=$(choose_swappiness)
    [[ "$swp" == "Cancel" || -z "$swp" ]] && return

    case "$type" in
        swapfile) setup_swapfile "$size" ;;
        zram)     setup_zram "$size" ;;
        zswap)    setup_zswap "$size" ;;
    esac

    apply_swappiness "$swp"

    echo ""
    log_info "Swap configuration complete."
    print_swap_info
}

main() {
    require_sudo
    while true; do
        local choice
        choice=$(menu_main)
        case "$choice" in
            "Configure swap") configure_swap ;;
            "View current swap")
                echo ""
                print_swap_info
                prompt_continue
                ;;
            "Quit"|"") exit 0 ;;
        esac
    done
}
