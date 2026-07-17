#!/usr/bin/env bash
# This is Dsx security module
# Detect all security modules and verify

set -euo pipefail
source "$BASE_DIR/core/common.sh"
source "$BASE_DIR/core/detect.sh"

pause() {
    read -n 1 -s -r -p $'\nPress Any key to continue...'
    echo
}

firewall_install() {
    if command -v nft &> /dev/null; then
        log_info "nftables já está instalado."
        return 0
    fi

    read -rp "Do you want to install the firewall? (y/n): " -n 1 -r confirm
    echo
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        log_error "Firewall installation was cancelled."
        return 1
    fi
    pkg_install nftables
}

firewall_enable() {
    log_info "Enabling firewall..."
    service_enable nftables || {
        log_error "Failed to enable firewall."
        return 1
    }
    log_success "Firewall has been enabled."
}

firewall_disable() {
    log_info "Disabling firewall..."
    service_disable nftables || {
        log_error "Failed to disable firewall."
        return 1
    }
    log_success "Firewall has been disabled."
}

firewall_status() {
    local db="$BASE_DIR/modules/data/services.db"
    local fw_status fw_boot rules tables services line
    local process service description

    clear

    echo "[MODULE] DSXSecurity - running (logs saved only on error)"
    echo

    [[ -f "$db" ]] || die "services.db not found: $db"

    if systemctl is-active --quiet nftables; then
        fw_status="Active"
    else
        fw_status="Inactive"
    fi

    if systemctl is-enabled --quiet nftables 2>/dev/null; then
        fw_boot="Enabled"
    else
        fw_boot="Disabled"
    fi

    rules=$(sudo nft list ruleset 2>/dev/null | grep -Ec 'accept|drop|reject' || true)
    tables=$(sudo nft list tables 2>/dev/null | wc -l) || true

    services=$(
        sudo ss -H -tulpn 2>/dev/null |
        sed -n 's/.*users:(("\([^"]*\)".*/\1/p' |
        sort -u |
        wc -l
    ) || true

    cat <<EOF
╭──────────────────────────────────────────────────────────────╮
│                    DSXSecurity Firewall                      │
├──────────────────────────────────────────────────────────────┤
│ Firewall       $fw_status
│ Startup        $fw_boot
│ Backend        nftables
│ Rules          $rules
│ Tables         $tables
│ Services       $services
╰──────────────────────────────────────────────────────────────╯

Detected Services
──────────────────────────────────────────────────────────────
EOF

    sudo ss -H -tulpn 2>/dev/null |
    awk '
    {
        split($5,a,":")
        port=a[length(a)]
        if (port > 49151)
            next
        proc="Unknown"

        if(match($0,/users:\(\("([^"]+)"/)){
            s=substr($0,RSTART,RLENGTH)
            sub(/users:\(\("/,"",s)
            sub(/".*/,"",s)
            proc=s
        }

        key = proc ":" port
        if (!(key in seen )) {
            seen[key] = 1

            if (proc in ports)
                ports[proc] = ports[proc] ", " port
            else
                ports[proc] = port
        }
    }
    END {
        for(i in ports)
            if (ports[i] != "")
                print i "|" ports[i]
    }' |
    sort |
    while IFS='|' read -r process ports; do

        line=$(
            awk -F'|' -v p="$process" '
                BEGIN{IGNORECASE=1}
                $1==p{
                    print
                    exit
                }
            ' "$db"
        )

        if [[ -n "$line" ]]; then
            IFS='|' read -r _ service description <<<"$line"
        else
            service="$process"
            description="Application not registered in DSXSecurity."
        fi

        printf "● %s\n" "$service"
        printf "  Process : %s\n" "$process"
        printf "  Ports   : %s\n" "$ports"
        printf "  About   : %s\n\n" "$description"

    done
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
        ) || true

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
        esac
    done
}

main() {
    local option
    local banner

    banner=$'\033[34m'"\
██████╗ ███████╗██╗  ██╗███████╗███████╗ ██████╗██╗   ██╗██████╗ ██╗████████╗██╗   ██╗
██╔══██╗██╔════╝╚██╗██╔╝██╔════╝██╔════╝██╔════╝██║   ██║██╔══██╗██║╚══██╔══╝╚██╗ ██╔╝
██║  ██║███████╗ ╚███╔╝ ███████╗█████╗  ██║     ██║   ██║██████╔╝██║   ██║    ╚████╔╝
██║  ██║╚════██║ ██╔██╗ ╚════██║██╔══╝  ██║     ██║   ██║██╔══██╗██║   ██║     ╚██╔╝
██████╔╝███████║██╔╝ ██╗███████║███████╗╚██████╗╚██████╔╝██║  ██║██║   ██║      ██║
╚═════╝ ╚══════╝╚═╝  ╚═╝╚══════╝╚══════╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝   ╚═╝      ╚═╝
\033[0m"

    while true; do
        option=$(
            printf "%s\n" \
                "Firewall" \
                "SSH" \
                "SELinux" \
                "AppArmor" \
                "Exit" |
            fzf \
                --ansi \
                --header "$banner" \
                --header-first \
                --prompt "dsxsecurity > " \
                --height=60% \
                --border \
                --reverse \
                --cycle
        ) || true

        case "$option" in
            "Firewall") firewall_menu ;;
            "SSH") ssh_menu ;;
            "SELinux") selinux_menu ;;
            "AppArmor") apparmor_menu ;;
            "Exit"|"") exit 0 ;;
        esac
    done
}

main