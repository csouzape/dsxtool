#!/usr/bin/env bash
# This is Dsx security module
# Detect all security modules and verify

set -euo pipefail
source "$BASE_DIR/core/common.sh"
source "$BASE_DIR/core/detect.sh"

DSXSEC_CONF_DIR="/etc/dsxsecurity"
DSXSEC_FW_STATE="$DSXSEC_CONF_DIR/firewall.conf"


pause() {
    read -n 1 -s -r -p $'\nPress Any key to continue...'
    echo
}


firewall_install() {
    local installed=false
    local enabled=false

    command -v nft &> /dev/null && installed=true
    systemctl is-enabled --quiet nftables 2>/dev/null && enabled=true

    if $installed && $enabled; then
        log_info "nftables já está instalado e habilitado."
        return 0
    fi

    if $installed && ! $enabled; then
        log_info "nftables já está instalado, mas não está habilitado."
        read -rn 1 -p "Deseja habilitar o firewall agora? (y/n): " confirm
        echo
        [[ "$confirm" =~ ^[Yy]$ ]] || {
            log_error "Ativação do firewall cancelada."
            return 1
        }
        firewall_enable
        return $?
    fi

    read -rn 1 -p "Deseja instalar o firewall? (y/n): " confirm
    echo
    [[ "$confirm" =~ ^[Yy]$ ]] || {
        log_error "Instalação do firewall cancelada."
        return 1
    }

    pkg_install nftables || {
        log_error "Falha ao instalar nftables."
        return 1
    }

    read -rn 1 -p "Deseja habilitar o firewall agora? (y/n): " confirm
    echo
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        firewall_enable
    fi
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


firewall_apply_profile() {
    local profile="$1"
    local extra_rules=""

    case "$profile" in
        home)
            extra_rules='ip saddr { 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16 } accept'
            ;;
        gaming)
            extra_rules='ip saddr { 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16 } accept
        udp dport { 1900, 5353 } accept'
            ;;
        public)
            extra_rules=''
            ;;
        *)
            log_error "Invalid profile: $profile"
            return 1
            ;;
    esac

    sudo nft -f - <<EOF
flush ruleset
table inet dsxsecurity {
    chain input {
        type filter hook input priority filter; policy drop;
        iif lo accept
        ct state established,related accept
        ct state invalid drop
        icmp type { echo-request, destination-unreachable, time-exceeded } accept
        icmpv6 type { echo-request, nd-neighbor-solicit, nd-neighbor-advert, nd-router-advert } accept
        $extra_rules
    }
    chain forward { type filter hook forward priority filter; policy drop; }
    chain output { type filter hook output priority filter; policy accept; }
}
EOF

    if [[ $? -ne 0 ]]; then
        log_error "Failed to apply profile '$profile'."
        return 1
    fi

    sudo mkdir -p "$DSXSEC_CONF_DIR"
    echo "PROFILE=$profile" | sudo tee "$DSXSEC_FW_STATE" > /dev/null
    log_success "Profile '$profile' applied."
}

firewall_current_profile() {
    [[ -f "$DSXSEC_FW_STATE" ]] && grep -oP '(?<=PROFILE=).*' "$DSXSEC_FW_STATE" || echo "none"
}


firewall_profile_preview() {
    case "$1" in
        "Home")
cat <<'EOF'
HOME — Trusted network (residence)

What it does:
  - Allows access from devices on your local network
    (other computers, phone, printer, etc.)
  - Blocks any connection attempt coming from the internet

Use when: you are at home, on your own router.
EOF
            ;;
        "Public")
cat <<'EOF'
PUBLIC — Untrusted network (third-party Wi-Fi)

What it does:
  - Blocks ALL incoming connections, even from the local network
  - Only allows responses to connections you started yourself

Use when: coffee shop, airport, hotel Wi-Fi, or any
network that is not your own.

Warning: if you access this machine via remote SSH,
new SSH connections will also be blocked under this profile.
EOF
            ;;
        "Gaming")
cat <<'EOF'
GAMING — Local network + device discovery

What it does:
  - Same as the Home profile
  - Opens ports used by games/apps to discover other
    devices on the same network (mDNS/SSDP)

Use when: local network gaming, Chromecast, DLNA,
media sharing.
EOF
            ;;
    esac
}

firewall_status() {
    local db="$BASE_DIR/modules/data/services.db"
    local fw_status fw_boot profile rules tables services line
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

    if [[ "$fw_status" == "Active" ]] && sudo nft list tables 2>/dev/null | grep -q dsxsecurity; then
        profile=$(firewall_current_profile)
    else
        profile="none"
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
│ Profile        $profile
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


firewall_confirm_and_apply() {
    local profile="$1" label="$2"

    clear
    echo "Selected profile: $label"
    echo
    firewall_profile_preview "$label"
    echo

    if [[ "$profile" == "public" ]] && systemctl is-active --quiet "$(ssh_service_name)" 2>/dev/null; then
        echo "Warning: SSH is active on this machine."
        echo "If you manage this computer remotely, new connections"
        echo "may stop working after this change."
        echo
    fi

    read -rn 1 -p "Apply profile '$label' now? (y/n): " confirm
    echo
    [[ "$confirm" =~ ^[Yy]$ ]] || {
        log_info "Operation cancelled."
        return 1
    }

    firewall_apply_profile "$profile"
}


firewall_set_profile() {
    export -f firewall_profile_preview
    local choice
    choice=$(
        printf "%s\n" "Home" "Public" "Gaming" "Back" |
        fzf --prompt "Select network profile > " \
            --height=80% --border --reverse \
            --preview 'firewall_profile_preview {}' \
            --preview-window=right:60%:wrap
    ) || return 0

    case "$choice" in
        "Home")   firewall_confirm_and_apply home   "Home" ;;
        "Public") firewall_confirm_and_apply public "Public" ;;
        "Gaming") firewall_confirm_and_apply gaming "Gaming" ;;
        *) return 0 ;;
    esac
    pause
}




ssh_service_name() {
    if systemctl list-unit-files --no-legend 2>/dev/null | grep -q '^sshd\.service'; then
        echo "sshd"
    elif systemctl list-unit-files --no-legend 2>/dev/null | grep -q '^ssh\.service'; then
        echo "ssh"
    else
        echo "sshd"
    fi
}

ssh_backup_config() {
    local conf="/etc/ssh/sshd_config"
    local backup="/etc/ssh/sshd_config.dsxsecurity.bak"

    [[ -f "$backup" ]] || sudo cp "$conf" "$backup" || {
        log_error "Failed to create backup of sshd_config."
        return 1
    }
}

ssh_set_option() {
    local key="$1"
    local value="$2"
    local conf="/etc/ssh/sshd_config"
    local tmp
    tmp=$(mktemp)

    sudo cp "$conf" "$tmp"

    if grep -Eq "^\s*#?\s*${key}\b" "$tmp"; then
        sudo sed -i -E "s|^\s*#?\s*${key}\b.*|${key} ${value}|" "$tmp"
    else
        echo "${key} ${value}" | sudo tee -a "$tmp" > /dev/null
    fi

    if ! sudo sshd -t -f "$tmp" 2>/dev/null; then
        log_error "Invalid config for '${key} ${value}'. Change discarded."
        rm -f "$tmp"
        return 1
    fi

    sudo cp "$tmp" "$conf"
    rm -f "$tmp"
    return 0
}

ssh_restart_service() {
    local svc
    svc=$(ssh_service_name)
    sudo systemctl restart "$svc" || {
        log_error "Failed to restart $svc. Check 'journalctl -u $svc'."
        return 1
    }
}



ssh_disable() {
    local svc
    svc=$(ssh_service_name)

    read -rn 1 -p "Are you sure you want to disable $svc? (y/n): " confirm
    echo
    [[ "$confirm" =~ ^[Yy]$ ]] || {
        log_info "Operation cancelled."
        return 1
    }

    log_info "Disabling $svc..."
    service_disable "$svc" || {
        log_error "Falha ao desabilitar $svc."
        return 1
    }
    log_success "$svc disabled."
}

ssh_status() {
    local svc conf status boot port root_login pass_auth
    local status_icon boot_icon port_note root_icon pass_icon
    local warnings=()

    svc=$(ssh_service_name)
    conf="/etc/ssh/sshd_config"

    clear
    echo "[MODULE] DSXSecurity - running (logs saved only on error)"
    echo

    systemctl is-active --quiet "$svc" && status="active" || status="inactive"
    systemctl is-enabled --quiet "$svc" 2>/dev/null && boot="yes" || boot="no"

    port=$(sudo grep -E '^\s*Port\s' "$conf" 2>/dev/null | awk '{print $2}') || port=""
    port="${port:-22}"

    root_login=$(sudo grep -E '^\s*PermitRootLogin\s' "$conf" 2>/dev/null | awk '{print $2}') || root_login=""
    root_login="${root_login:-yes}"

    pass_auth=$(sudo grep -E '^\s*PasswordAuthentication\s' "$conf" 2>/dev/null | awk '{print $2}') || pass_auth=""
    pass_auth="${pass_auth:-yes}"


    if [[ "$status" == "active" ]]; then
        status_icon="✓ On"
    else
        status_icon="✗ Off"
    fi

    if [[ "$boot" == "yes" ]]; then
        boot_icon="✓ Yes"
    else
        boot_icon="✗ No"
    fi

    if [[ "$port" == "22" ]]; then
        port_note="$port (default port, most targeted by automated attacks)"
        warnings+=("Changing the default port (22) reduces automated intrusion attempts.")
    else
        port_note="$port (custom port)"
    fi

    if [[ "$root_login" =~ ^(yes|prohibit-password)$ ]]; then
        root_icon="✗ Allowed"
        warnings+=("Disabling direct root login improves security.")
    else
        root_icon="✓ Blocked"
    fi

    if [[ "$pass_auth" == "yes" ]]; then
        pass_icon="✗ Allowed"
        warnings+=("Disabling password login (key-only) prevents brute-force attacks.")
    else
        pass_icon="✓ Blocked"
    fi

    cat <<EOF
╭──────────────────────────────────────────────────────────────╮
│                      DSXSecurity SSH                          │
├──────────────────────────────────────────────────────────────┤
│ Remote access enabled?........... $status_icon
│ Starts automatically on boot?.... $boot_icon
│ Port in use....................... $port_note
│ Direct root login allowed?....... $root_icon
│ Password login allowed?.......... $pass_icon
╰──────────────────────────────────────────────────────────────╯
EOF

    if (( ${#warnings[@]} > 0 )); then
        echo
        echo "Recommendations:"
        local w
        for w in "${warnings[@]}"; do
            echo "  • $w"
        done
    else
        echo
        echo "✓ SSH configuration is within recommended settings."
    fi
}

ssh_change_port() {
    local new_port

    read -rp "Nova porta SSH (1024-65535): " new_port

    if ! [[ "$new_port" =~ ^[0-9]+$ ]] || (( new_port < 1024 || new_port > 65535 )); then
        log_error "Porta inválida."
        return 1
    fi

    ssh_backup_config || return 1
    ssh_set_option "Port" "$new_port" || return 1
    ssh_restart_service || return 1

    log_success "SSH port changed to $new_port."
    log_info "Remember to open this port in your firewall and adjust your current session before exiting."
}

ssh_disable_root_login() {
    ssh_backup_config || return 1
    ssh_set_option "PermitRootLogin" "no" || return 1
    ssh_restart_service || return 1
    log_success "SSH root login disabled."
}

ssh_disable_password_login() {
    if ! sudo find /root /home -maxdepth 2 -name "authorized_keys" 2>/dev/null | grep -q .; then
        log_error "No authorized_keys found in any user."
        read -rn 1 -p "Continue anyway? (y/n): " confirm
        echo
        [[ "$confirm" =~ ^[Yy]$ ]] || {
            log_info "Operation cancelled."
            return 1
        }
    fi

    ssh_backup_config || return 1
    ssh_set_option "PasswordAuthentication" "no" || return 1
    ssh_restart_service || return 1
    log_success "Password authentication disabled."
}

ssh_harden() {
    log_info "Applying SSH hardening (root login off, password auth off)..."
    ssh_backup_config || return 1
    ssh_disable_root_login || return 1
    ssh_disable_password_login || return 1
    log_success "SSH hardening completed."
}

ssh_restore() {
    local conf="/etc/ssh/sshd_config"
    local backup="/etc/ssh/sshd_config.dsxsecurity.bak"

    [[ -f "$backup" ]] || {
        log_error "Backup file not found in $backup."
        return 1
    }

    read -rn 1 -p "Restore sshd_config from backup? (y/n): " confirm
    echo
    [[ "$confirm" =~ ^[Yy]$ ]] || {
        log_info "Restore cancelled."
        return 1
    }

    if ! sudo sshd -t -f "$backup" 2>/dev/null; then
        log_error "Backup file is invalid. Restore cancelled."
        return 1
    fi

    sudo cp "$backup" "$conf"
    ssh_restart_service || return 1
    log_success "sshd_config restored from backup."
}

ssh_install() {
    if command -v sshd &> /dev/null || [[ -x /usr/sbin/sshd ]]; then
        log_info "OpenSSH já está instalado."
        return 0
    fi

    read -rn 1 -p "Install OpenSSH? (y/n): " confirm
    echo
    [[ "$confirm" =~ ^[Yy]$ ]] || {
        log_error "Installation cancelled."
        return 1
    }

    pkg_install openssh || {
        log_error "Failed to install OpenSSH."
        return 1
    }
    log_success "OpenSSH installed."
}

ssh_enable() {
    local svc
    svc=$(ssh_service_name)
    log_info "Enabling $svc..."
    service_enable "$svc" || {
        log_error "Failed to enable $svc."
        return 1
    }
    log_success "$svc enabled."
}


ssh_menu() {
    local option
    while true; do
        option=$(
            printf "%s\n" \
                "Status" \
                "Install" \
                "Enable" \
                "Disable" \
                "Harden" \
                "Change Port" \
                "Disable Root Login" \
                "Disable Password Login" \
                "Restore" \
                "Back" |
            fzf \
                --prompt "SSH Menu > " \
                --height=60% \
                --border \
                --reverse \
                --cycle
        ) || true

        case "$option" in
            "Status") ssh_status; pause ;;
            "Install") ssh_install; pause ;;
            "Enable") ssh_enable; pause ;;
            "Disable") ssh_disable; pause ;;
            "Harden") ssh_harden; pause ;;
            "Change Port") ssh_change_port; pause ;;
            "Disable Root Login") ssh_disable_root_login; pause ;;
            "Disable Password Login") ssh_disable_password_login; pause ;;
            "Restore") ssh_restore; pause ;;
            "Back"|"") return 0 ;;
        esac
    done
}


firewall_menu() {
    local option
    while true; do
        option=$(
            printf "%s\n" \
                "Status" \
                "Change Profile" \
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
            "Change Profile")
                firewall_set_profile
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

security_overview() {
    clear
    local fw_active fw_label ssh_active ssh_label svc

    if systemctl is-active --quiet nftables && sudo nft list tables 2>/dev/null | grep -q dsxsecurity; then
        fw_active=true
        fw_label="Protected (profile: $(firewall_current_profile))"
    else
        fw_active=false
        fw_label="Vulnerable (firewall is off)"
    fi

    svc=$(ssh_service_name)
    if systemctl is-active --quiet "$svc"; then
        ssh_active=true
        if sudo grep -Eq '^\s*PasswordAuthentication\s+no' /etc/ssh/sshd_config 2>/dev/null; then
            ssh_label="Running (key-only login)"
        else
            ssh_label="Running (password login allowed)"
        fi
    else
        ssh_active=false
        ssh_label="Not running"
    fi

    cat <<EOF
+------------------------------------------------+
|              DSXSecurity Overview               |
+------------------------------------------------+
| Firewall       $fw_label
| SSH            $ssh_label
+------------------------------------------------+
EOF
}





main() {
    local option
    local banner

    banner=$'\033[34m'"\
██████╗ ███████╗██╗  ██╗███████╗███████╗ ██████╗██╗   ██╗██████╗ ██╗████████╗██╗   ██╗
██╔══██╗██╔════╝╚██╗██╔╝██╔════╝██╔════╝██╔════╝██╔════╝██║   ██║██╔══██╗██║╚══██╔══╝╚██╗ ██╔╝
██║  ██║███████╗ ╚███╔╝ ███████╗█████╗  ██║     ██║   ██║██████╔╝██║   ██║    ╚████╔╝
██║  ██║╚════██║ ██╔██╗ ╚════██║██╔══╝  ██║     ██║   ██║██╔══██╗██║   ██║     ╚██╔╝
██████╔╝███████║██╔╝ ██╗███████║███████╗╚██████╗╚██████╔╝██║  ██║██║   ██║      ██║
╚═════╝ ╚══════╝╚═╝  ╚═╝╚══════╝╚══════╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝   ╚═╝      ╚═╝
\033[0m"

    while true; do
        option=$(
            printf "%s\n" \
                "Overview" \
                "Firewall" \
                "SSH" \
                "Exit" |
            fzf \
                --ansi \
                --header "$banner" \
                --header-first \
                --prompt "dsxsecurity > " \
                --height=100% \
                --border \
                --reverse \
                --cycle \
                --preview '
                    case {} in
                        "Overview") echo "See a quick summary of the security status." ;;
                        "Firewall") echo "Manage the system firewall: status, install, enable, disable, and switch between Home, Public, and Gaming profiles." ;;
                        "SSH") echo "Audit and harden the SSH service: check status, change port, disable root login, disable password login, restore backup." ;;
                        "Exit") echo "Close DSXSecurity." ;;
                    esac
                ' \
                --preview-window=right:50%:wrap
        ) || true

        case "$option" in
            "Overview") security_overview; pause ;;
            "Firewall") firewall_menu ;;
            "SSH") ssh_menu ;;
            "Exit"|"") exit 0 ;;
        esac
    done
}


main
