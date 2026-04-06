#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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
        log_info "This module requires sudo privileges."
        sudo -v || die "Failed to obtain sudo privileges."
    fi
}

prompt_continue() {
    read -rp "$(echo -e "${YELLOW}Press Enter to continue...${RESET}")" < /dev/tty
}

require() {
    command -v "$1" >/dev/null 2>&1 || die "Missing dependency: $1. Please install it before running dsxswap."
}

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

is_arch() { [[ -f /etc/arch-release ]]; }

has_zram_generator() {
    command -v zramctl >/dev/null 2>&1 && {
        (command -v pacman >/dev/null 2>&1 && pacman -Q zram-generator >/dev/null 2>&1) ||
        [[ -f /usr/lib/systemd/system-generators/zram-generator ]]
    }
}

size_to_mib() {
    numfmt --from=iec --to-unit=1M "$1"
}

print_swap_info() {
    echo ""
    if [[ -f /proc/swaps ]] && awk 'NR>1' /proc/swaps | grep -q .; then
        log_info "Active swap devices:"
        awk 'NR>1 {printf "  %-35s Type: %-10s Size: %s KB\n", $1, $2, $3}' /proc/swaps
    else
        log_warn "No active swap found."
    fi
    echo ""
    log_info "Current swappiness: $(cat /proc/sys/vm/swappiness)"
    echo ""
}

menu_main() {
    printf "%s\n" \
        "Configure swap" \
        "View current swap" \
        "Remove swap" \
        "Quit" \
    | fzf_menu --prompt="  dsxswap > "
}

choose_type() {
    printf "%s\n" "swapfile" "zram" "zswap" "Cancel" \
    | fzf_menu --prompt="  Type > "
}

choose_zram_method() {
    printf "%s\n" "zram-generator" "manual (modprobe)" "Cancel" \
    | fzf_menu --prompt="  ZRAM method > "
}

choose_size() {
    printf "%s\n" "512M" "1G" "2G" "4G" "8G" "16G" "Cancel" \
    | fzf_menu --prompt="  Size > "
}

choose_swappiness() {
    printf "%s\n" "10" "20" "40" "60" "80" "100" "Cancel" \
    | fzf_menu --prompt="  Swappiness (kernel default: 60) > "
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
    if sudo swapon --show | grep -q "^$file"; then
        log_warn "Deactivating existing swapfile..."
        sudo swapoff "$file"
    fi
    sudo rm -f "$file"
    sudo fallocate -l "$size" "$file" || sudo dd if=/dev/zero of="$file" bs=1M count="$(size_to_mib "$size")" status=none
    sudo chmod 600 "$file"
    sudo mkswap "$file" >/dev/null
    sudo swapon "$file"
    if ! grep -q "^$file" /etc/fstab; then
        echo "$file none swap sw 0 0" | sudo tee -a /etc/fstab >/dev/null
        log_info "Swapfile entry added to /etc/fstab."
    fi
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
    if sudo systemctl restart systemd-zram-setup@zram0.service 2>/dev/null; then
        log_info "ZRAM configured and active via zram-generator."
    else
        log_warn "Could not restart zram unit — a reboot may be required."
    fi
}

setup_zram_manual() {
    local size="$1"
    local bytes
    bytes=$(numfmt --from=iec "$size")
    log_info "Configuring ZRAM manually ($size)..."
    if grep -q "^/dev/zram0" /proc/swaps 2>/dev/null; then
        log_warn "Deactivating existing /dev/zram0..."
        sudo swapoff /dev/zram0
        echo 1 | sudo tee /sys/block/zram0/reset >/dev/null 2>&1 || true
    fi
    sudo modprobe zram
    echo "$bytes" | sudo tee /sys/block/zram0/disksize >/dev/null
    sudo mkswap /dev/zram0 >/dev/null
    sudo swapon /dev/zram0
    log_info "ZRAM active: /dev/zram0 ($size)."
}

setup_zram() {
    local size="$1"
    if is_arch && has_zram_generator; then
        local method
        method=$(choose_zram_method)
        [[ "$method" == "Cancel" || -z "$method" ]] && return
        case "$method" in
            "zram-generator")    setup_zram_generator "$size" ;;
            "manual (modprobe)") setup_zram_manual "$size" ;;
        esac
    else
        log_info "zram-generator not detected — using manual setup."
        setup_zram_manual "$size"
    fi
}

setup_zswap() {
    local size="$1"
    log_info "Enabling zswap kernel module..."
    if ! sudo modprobe zswap 2>/dev/null; then
        log_warn "modprobe zswap failed — may already be built-in."
    fi
    if [[ -f /sys/module/zswap/parameters/enabled ]]; then
        echo 1 | sudo tee /sys/module/zswap/parameters/enabled >/dev/null
        log_info "zswap enabled."
    else
        log_warn "zswap sysfs path not found — skipping enable step."
    fi
    log_info "Setting up backing swapfile ($size)..."
    setup_swapfile "$size"
    log_info "zswap active with $size swapfile as backing store."
}

remove_swap() {
    echo ""
    if ! awk 'NR>1' /proc/swaps | grep -q .; then
        log_warn "No active swap to remove."
        prompt_continue
        return
    fi
    print_swap_info
    read -rp "$(echo -e "${YELLOW}Are you sure you want to remove all active swap? [y/n]: ${RESET}")" answer < /dev/tty
    [[ "$answer" =~ ^[Yy]$ ]] || return
    if sudo swapon --show | grep -q "^/swapfile"; then
        sudo swapoff /swapfile
        sudo rm -f /swapfile
        sudo sed -i '\|^/swapfile|d' /etc/fstab
        log_info "Swapfile removed."
    fi
    if grep -q "^/dev/zram" /proc/swaps 2>/dev/null; then
        sudo swapoff /dev/zram0 2>/dev/null || true
        sudo modprobe -r zram 2>/dev/null || true
        sudo rm -f /etc/systemd/zram-generator.conf.d/zram.conf
        log_info "ZRAM removed."
    fi
    log_info "All swap removed."
    prompt_continue
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
    prompt_continue
}

main() {
    require_sudo
    while true; do
        local choice
        choice=$(menu_main)
        case "$choice" in
            "Configure swap")    configure_swap ;;
            "View current swap") print_swap_info; prompt_continue ;;
            "Remove swap")       remove_swap ;;
            "Quit"|"")           exit 0 ;;
        esac
    done
}

main "$@"