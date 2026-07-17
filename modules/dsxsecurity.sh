#!/usr/bin/env bash
# This is Dsx security module
# Detect all security modules and verify
set -euo pipefail
source "$BASE_DIR/core/common.sh"
source "$BASE_DIR/core/detect.sh"

pause(){
    read -n 1 -s -r -p $'\nPressione qualquer tecla para continuar...'
    echo
}

firewall_install(){
    if command -v nft &> /dev/null; then
        log_info "nftables já está instalado."
        return 0
    fi

    read -rp "Do you want to install the firewall? (y/n):" -n 1 -r confirm
    echo
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        log_error "Firewall installation was cancelled."
        return 1
    fi
    pkg_install nftables
}

firewall_enable(){
    log_info "Enabling firewall..."
    service_enable nftables || {
        log_error "Failed to enable firewall."
        return 1
    }
    log_success "Firewall has been enabled."
}

firewall_disable(){
    log_info "Disabling firewall..."
    service_disable nftables || {
        log_error "Failed to disable firewall."
        return 1
    }
    log_success "Firewall has been disabled."
}

firewall_status(){
    local service_status
    local enabled_status
    local rules_count
    local table_count
    local port_count

    echo "[MODULE] DSXSecurity - running (logs saved only on error)"

    if systemctl is-active --quiet nftables; then
        service_status="Active"
    else
        service_status="Inactive"
    fi

    if systemctl is-enabled --quiet nftables 2>/dev/null; then
        enabled_status="Enabled"
    else
        enabled_status="Disabled"
    fi

    rules_count=$(sudo nft list ruleset 2>/dev/null | grep -cE '^\s*(tcp|udp|ip|ip6|meta|ct|iif|oif|accept|drop|reject|counter|log)\b' || true)
    table_count=$(sudo nft list tables 2>/dev/null | grep -c . || true)
    port_count=$(ss -tuln 2>/dev/null | grep -c LISTEN || true)

    echo
    echo "================ Firewall Report ================"
    printf "%-22s %s\n" "Service:" "$service_status"
    printf "%-22s %s\n" "Start at Boot:" "$enabled_status"
    printf "%-22s %s\n" "Backend:" "nftables"
    printf "%-22s %s\n" "Rules Loaded:" "$rules_count"
    printf "%-22s %s\n" "Networks Protected:" "$table_count"
    printf "%-22s %s\n" "Open Ports:" "$port_count"
    echo "------------------------------------------------"

    if [[ "$port_count" -gt 0 ]]; then
        echo "Listening on:"
        ss -tuln 2>/dev/null \
            | awk '/LISTEN/ { n=split($5,a,":"); print a[n] }' \
            | sort -nu \
            | sed 's/^/  • port /'
    else
        echo "No open ports detected."
    fi
    echo "================================================"
}


firewall_menu() {
    local option
    while true; do
        option=$(
            printf "%s\n" \
                "Status" \
                "Install" \
                "Enable" \
                "Disable" \
                "Back" |
            fzf \
                --prompt "Firewall Menu > " \
                --height=60% \
                --border \
                --reverse \
                --cycle
        )

        case "$option" in
            "Status")
                firewall_status
                pause
                ;;
            "Install")
                firewall_install
                pause
                ;;
            "Enable")
                firewall_enable
                pause
                ;;
            "Disable")
                firewall_disable
                pause
                ;;
            "Back"|"")
                return 0
                ;;
            *)
                ;;
        esac
    done
}

main(){
    local option
    option=$(
        printf "%s\n" \
            "Firewall" \
            "SSH" \
            "SELinux" \
            "AppArmor" \
            "Exit" |
        fzf \
            --prompt "dsxsecurity > " \
            --height=60% \
            --border \
            --reverse \
            --cycle
    )

    case "$option" in
        "Firewall")
            firewall_menu
            ;;
        "SSH")
            ssh_menu
            ;;
        "SELinux")
            selinux_menu
            ;;
        "AppArmor")
            apparmor_menu
            ;;
        "Exit"|"")
            exit 0
            ;;
        *)
            ;;
    esac
}

main
