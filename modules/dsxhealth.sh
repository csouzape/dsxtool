#!/usr/bin/env bash
set -uo pipefail

RED=$'\033[0;31m';   GREEN=$'\033[0;32m';  YELLOW=$'\033[1;33m'
BLUE=$'\033[0;34m';  CYAN=$'\033[0;36m';   MAGENTA=$'\033[0;35m'
BOLD=$'\033[1m';     DIM=$'\033[2m';       RESET=$'\033[0m'

log_step()    { echo -e "${CYAN}${BOLD}[STEP]${RESET} $*"; }
log_success() { echo -e "${GREEN}${BOLD}[ OK ]${RESET} $*"; }
log_skip()    { echo -e "${DIM}[SKIP] $*${RESET}"; }

_section() {
    echo
    echo -e "${MAGENTA}${BOLD}━━━━━ $* ━━━━━${RESET}"
}

_fzf_menu() {
    local tmp_in tmp_out
    tmp_in=$(mktemp)
    tmp_out=$(mktemp)
    cat > "$tmp_in"
    fzf "$@" < "$tmp_in" > "$tmp_out" || true
    cat "$tmp_out"
    rm -f "$tmp_in" "$tmp_out"
}

_disk_used_pct() { df -P /  | awk 'NR==2{gsub(/%/,"",$5); print $5+0}'; }
_disk_used_kb()  { df -Pk / | awk 'NR==2{print $3+0}'; }
_disk_avail_kb() { df -Pk / | awk 'NR==2{print $4+0}'; }


_fmt_kb() {
    awk -v k="${1:-0}" 'BEGIN{
        b = k * 1024; split("B KB MB GB TB PB", u, " "); i = 1;
        while (b >= 1024 && i < 6) { b /= 1024; i++ }
        printf("%.1f %s", b, u[i])
    }'
}


_disk_bar() {
    local pct=${1:-0} width=${2:-24} filled i color bar=""
    (( pct < 0 )) && pct=0
    (( pct > 100 )) && pct=100
    filled=$(( pct * width / 100 ))
    if   (( pct >= 90 )); then color=$RED
    elif (( pct >= 70 )); then color=$YELLOW
    else                        color=$GREEN
    fi
    for (( i = 0; i < width; i++ )); do
        if (( i < filled )); then bar+="█"; else bar+="░"; fi
    done
    printf '%b%s%b' "$color" "$bar" "$RESET"
}


pkg_clean_cache() {
    log_step "Cleaning package manager cache..."
    case "$DISTRO" in
        arch)
            if command -v paccache &>/dev/null; then
                sudo paccache -rk1
                sudo paccache -ruk0
            else
                sudo pacman -Sc --noconfirm
            fi
            ;;
        debian)
            sudo apt clean
            sudo apt autoclean -y
            ;;
        fedora)
            sudo dnf clean all
            ;;
        *)
            log_warn "Unsupported distro for cache cleaning."
            ;;
    esac
    log_info "Package cache cleaned."
}

pkg_remove_orphans() {
    log_step "Removing orphan packages..."
    case "$DISTRO" in
        arch)
            local orphans
            orphans=$(pacman -Qtdq 2>/dev/null || true)
            if [[ -n "$orphans" ]]; then
                # shellcheck disable=SC2086
                sudo pacman -Rns $orphans --noconfirm
                log_info "Orphan packages removed."
            else
                log_skip "No orphan packages found."
            fi
            ;;
        debian)
            sudo apt autoremove --purge -y
            ;;
        fedora)
            sudo dnf autoremove -y
            ;;
        *)
            log_warn "Unsupported distro for orphan removal."
            ;;
    esac
}

clean_journal() {
    log_step "Vacuuming systemd journal (keeping last 2 weeks / 200M cap)..."
    sudo journalctl --vacuum-time=2weeks
    sudo journalctl --vacuum-size=200M
    log_info "Journal vacuumed."
}

clean_coredumps() {
    log_step "Clearing systemd coredumps..."
    if [[ -d /var/lib/systemd/coredump ]]; then
        sudo find /var/lib/systemd/coredump -type f -delete 2>/dev/null || true
        log_info "Coredumps cleared."
    else
        log_skip "No coredump directory found."
    fi
}

clean_user_cache() {
    log_step "Cleaning user cache (~/.cache)..."
    rm -rf "${HOME:?}/.cache/"* 2>/dev/null || true
    log_info "User cache cleaned."
}

clean_thumbnails() {
    log_step "Cleaning thumbnail cache (~/.cache/thumbnails)..."
    rm -rf "${HOME:?}/.cache/thumbnails/"* 2>/dev/null || true
    log_info "Thumbnail cache cleaned."
}

empty_trash() {
    log_step "Emptying trash..."
    rm -rf "${HOME:?}/.local/share/Trash/files/"* \
           "${HOME:?}/.local/share/Trash/info/"* 2>/dev/null || true
    log_info "Trash emptied."
}

clean_temp() {
    local choice

    choice=$(
        printf "%s\n" "Older than 7 days (safe)" "Remove everything" |
        _fzf_menu --prompt "Temp cleanup mode > " --height=40% --border --reverse
    ) || true

    case "$choice" in
        "Remove everything")
            log_warn "Removing ALL files in /tmp and /var/tmp, including files in use..."
            sudo find /tmp     -mindepth 1 -xdev -delete 2>/dev/null || true
            sudo find /var/tmp -mindepth 1 -xdev -delete 2>/dev/null || true
            ;;
        "Older than 7 days (safe)"|*)
            log_step "Removing temp files older than 7 days (/tmp, /var/tmp)..."
            sudo find /tmp     -mindepth 1 -xdev -atime +7 -delete 2>/dev/null || true
            sudo find /var/tmp -mindepth 1 -xdev -atime +7 -delete 2>/dev/null || true
            ;;
    esac

    log_info "Temporary files cleaned."
}

clean_flatpak() {
    if ! command -v flatpak &>/dev/null; then
        log_skip "Flatpak not installed."
        return 0
    fi
    log_step "Removing unused Flatpak runtimes..."
    flatpak uninstall --unused -y
    log_info "Unused Flatpaks removed."
}

prune_docker() {
    if ! command -v docker &>/dev/null; then
        log_skip "Docker not installed."
        return 0
    fi
    log_step "Pruning unused Docker data (images, containers, networks)..."
    if docker info &>/dev/null; then
        docker system prune -af
    elif sudo docker info &>/dev/null; then
        sudo docker system prune -af
    else
        log_warn "Could not access the Docker daemon. Skipping."
    fi
}

trim_ssd() {
    log_step "Running fstrim on all mounted filesystems..."
    sudo fstrim -av
    log_info "SSD trim completed."
}

check_failed_services() {
    log_step "Checking for failed systemd services..."
    local failed
    failed=$(systemctl --failed --no-legend --no-pager 2>/dev/null || true)
    if [[ -z "$failed" ]]; then
        log_success "No failed services. System is healthy."
    else
        log_warn "Failed services detected:"
        systemctl --failed --no-pager
    fi
}

DISK_REPORT_LOG_DIR="${DISK_REPORT_LOG_DIR:-$HOME/.local/share/dsxtool/reports}"

_disk_report_body() {
    log_step "Filesystem usage:"
    df -hT -x tmpfs -x devtmpfs -x squashfs 2>/dev/null || df -h
    echo
    log_step "Top space users in your home directory:"
    du -h -d1 "$HOME" 2>/dev/null | sort -rh | head -n 11
    echo
    log_step "Largest known caches:"
    du -sh "$HOME/.cache" "$HOME/.local/share/Trash" 2>/dev/null || true
}

_strip_ansi() { sed -r 's/\x1b\[[0-9;]*m//g'; }

disk_report() {
    local report
    report=$(_disk_report_body)

    echo -e "$report"
    echo

    local confirm
    read -rp "$(echo -e "${YELLOW}Save this report to a log file? (y/n): ${RESET}")" confirm < /dev/tty
    if [[ ! "$confirm" =~ ^[YySs]$ ]]; then
        log_skip "Report not saved."
        return 0
    fi

    local stamp logfile
    stamp=$(date +%Y%m%d-%H%M%S)
    logfile="$DISK_REPORT_LOG_DIR/disk-report-$stamp.log"
    mkdir -p "$DISK_REPORT_LOG_DIR"
    {
        echo "dsxtool disk usage report — $(date)"
        echo "============================================================"
        echo "$report" | _strip_ansi
    } > "$logfile"
    log_success "Report saved to ${BOLD}$logfile${RESET}"
}

full_cleanup() {
    log_warn "Running full safe cleanup — multiple operations will be performed."
    _run_task "Package Cache"     pkg_clean_cache
    _run_task "Orphan Packages"   pkg_remove_orphans
    _run_task "Journal Logs"      clean_journal
    _run_task "Coredumps"         clean_coredumps
    _run_task "User Cache"        clean_user_cache
    _run_task "Thumbnail Cache"   clean_thumbnails
    _run_task "Trash"             empty_trash
    _run_task "Temp Files"        clean_temp
    _run_task "Unused Flatpaks"   clean_flatpak
}

_run_task() {
    local label="$1" fn="$2"
    local before after freed
    _section "$label"
    before=$(_disk_used_kb)
    "$fn"
    after=$(_disk_used_kb)
    freed=$(( before - after ))
    if   (( freed > 0 )); then
        log_success "Freed ${BOLD}$(_fmt_kb "$freed")${RESET}${GREEN} in this step.${RESET}"
    elif (( freed < 0 )); then
        log_info "Disk usage grew by $(_fmt_kb $(( -freed ))) (normal for updates/installs)."
    else
        log_skip "No measurable disk change."
    fi
}

_print_summary() {
    local before_kb=$1 after_kb=$2 before_pct=$3 after_pct=$4
    local freed_kb=$(( before_kb - after_kb ))
    local pct_diff=$(( before_pct - after_pct ))
    local change

    if   (( pct_diff > 0 )); then change="${GREEN}▼ ${pct_diff}% freed${RESET}"
    elif (( pct_diff < 0 )); then change="${YELLOW}▲ $(( -pct_diff ))% more used${RESET}"
    else                          change="${DIM}no change${RESET}"
    fi

    echo
    echo -e "${MAGENTA}${BOLD}╔═══════════════════ MAINTENANCE SUMMARY ═══════════════════╗${RESET}"
    if   (( freed_kb > 0 )); then
        echo -e "  ${GREEN}${BOLD}Space reclaimed:${RESET}  $(_fmt_kb "$freed_kb")"
    elif (( freed_kb < 0 )); then
        echo -e "  ${YELLOW}${BOLD}Disk usage grew:${RESET}  $(_fmt_kb $(( -freed_kb )))"
    else
        echo -e "  ${DIM}No net change in disk usage.${RESET}"
    fi
    echo -e "  Disk / usage:    ${BOLD}${before_pct}%${RESET} → ${BOLD}${after_pct}%${RESET}   (${change})"
    echo -e "  Free space now:  ${BOLD}$(_fmt_kb "$(_disk_avail_kb)")${RESET}"
    echo -e "  $(_disk_bar "$after_pct" 50)"
    echo -e "${MAGENTA}${BOLD}╚═══════════════════════════════════════════════════════════╝${RESET}"
}

# Module-private banner. Must NOT clobber the global $BANNER used by the main
# menu in install.sh, otherwise returning to the main menu shows this ASCII.
_MAINT_BANNER=$(printf '\e[38;2;249;226;175m')
_MAINT_BANNER+=$(cat <<'EOF'
██████╗ ███████╗██╗  ██╗██╗  ██╗███████╗ █████╗ ██╗  ████████╗██╗  ██╗
██╔══██╗██╔════╝╚██╗██╔╝██║  ██║██╔════╝██╔══██╗██║  ╚══██╔══╝██║  ██║
██║  ██║███████╗ ╚███╔╝ ███████║█████╗  ███████║██║     ██║   ███████║
██║  ██║╚════██║ ██╔██╗ ██╔══██║██╔══╝  ██╔══██║██║     ██║   ██╔══██║
██████╔╝███████║██╔╝ ██╗██║  ██║███████╗██║  ██║███████╗██║   ██║  ██║
╚═════╝ ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚══════╝╚═╝   ╚═╝  ╚═╝
EOF
)
_MAINT_BANNER+=$(printf '\e[0m')

_maintenance_preview() {
    case "$1" in
        "1 - Update System")            echo "Updates the system so your apps and security fixes stay current." ;;
        "2 - Empty Trash")              echo "Permanently deletes files in the trash folder." ;;
        "3 - Clean Temp Files")         echo "Removes temporary files from /tmp and /var/tmp that are no longer needed." ;;
        "4 - Clear Old Package Cache")  echo "Removes old package versions saved by the system to free space safely." ;;
        "5 - Remove Unused Programs")   echo "Deletes packages that were only needed for other programs and are no longer used." ;;
        "6 - Clear App Temp Files")     echo "Deletes temporary files left behind by apps and the desktop environment." ;;
        "7 - Clear Thumbnail Cache")    echo "Removes cached thumbnails so the image cache does not grow too much." ;;
        "8 - Clear Old System Logs")    echo "Removes old log entries so the system stays lighter and easier to manage." ;;
        "9 - Check for Problems")       echo "Shows whether any important background services are failing." ;;
        "10 - See What Uses Space")     echo "Shows which folders are using the most disk space." ;;
        "11 - Remove Unused Flatpak")   echo "Cleans up Flatpak runtimes and extensions you no longer use." ;;
        "12 - Clean Docker Leftovers")  echo "Removes unused Docker data to free space if you use containers." ;;
        "13 - Full Cleanup")           echo "Runs the most useful cleanup actions in one go." ;;
        "0 - Exit")                     echo "Closes this menu and returns to the main dsxtool menu." ;;
    esac
}
export -f _maintenance_preview


system_maintenance() {
    while true; do
        clear

        local selections fzf_header used_pct free_h bar
        used_pct=$(_disk_used_pct)
        free_h=$(_fmt_kb "$(_disk_avail_kb)")
        bar=$(_disk_bar "$used_pct" 24)

        fzf_header="$(printf '%b' "$_MAINT_BANNER\n\n${CYAN}${BOLD}Disk /${RESET}  $bar  ${BOLD}${used_pct}%${RESET} used  •  ${free_h} free\n\n[TAB] Select  [ENTER] Run  [ESC] Back")"

        selections=$(printf '%s\n' \
            "1 - Update System" \
            "2 - Empty Trash" \
            "3 - Clean Temp Files" \
            "4 - Clear Old Package Cache" \
            "5 - Remove Unused Programs" \
            "6 - Clear App Temp Files" \
            "7 - Clear Thumbnail Cache" \
            "8 - Clear Old System Logs" \
            "9 - Check for Problems" \
            "10 - See What Uses Space" \
            "11 - Remove Unused Flatpak" \
            "12 - Clean Docker Leftovers" \
            "13 - Full Cleanup" \
            "0 - Exit" \
            | _fzf_menu -m \
                  --ansi \
                  --prompt="Maintenance > " \
                  --header="$fzf_header" \
                  --height=100% \
                  --layout=reverse \
                  --border=rounded \
                  --pointer="▶" \
                  --marker="✓" \
                  --color="bg:#121212,bg+:#1e1e1e,fg:#d1d1d1,fg+:#ffffff,hl:#89b4fa,prompt:#cba6f7,pointer:#f38ba8,marker:#a6e3a1,header:#f1f1f1,border:#2a2a2a" \
                  --no-info \
                  --preview-window="right:42%:wrap" \
                  --preview='bash -c "_maintenance_preview {}"')

        [[ -z "$selections" ]] && return 0

        local before_kb before_pct
        before_kb=$(_disk_used_kb)
        before_pct=$(_disk_used_pct)

        local ran_any=0
        while read -r task; do
            [[ -z "$task" ]] && continue
            case "$task" in
                "1 - Update System")           _run_task "Update System"             pkg_update ;;
                "2 - Empty Trash")             _run_task "Empty Trash"              empty_trash ;;
                "3 - Clean Temp Files")        _run_task "Clean Temp Files"         clean_temp ;;
                "4 - Clear Old Package Cache") _run_task "Clear Old Package Cache"  pkg_clean_cache ;;
                "5 - Remove Unused Programs")  _run_task "Remove Unused Programs"   pkg_remove_orphans ;;
                "6 - Clear App Temp Files")    _run_task "Clear App Temp Files"     clean_user_cache ;;
                "7 - Clear Thumbnail Cache")   _run_task "Clear Thumbnail Cache"    clean_thumbnails ;;
                "8 - Clear Old System Logs")   _run_task "Clear Old System Logs"    clean_journal ;;
                "9 - Check for Problems")      _run_task "Check for Problems"       check_failed_services ;;
                "10 - See What Uses Space")    _run_task "See What Uses Space"      disk_report ;;
                "11 - Remove Unused Flatpak")  _run_task "Remove Unused Flatpak"    clean_flatpak ;;
                "12 - Clean Docker Leftovers") _run_task "Clean Docker Leftovers"   prune_docker ;;
                "13 - Full Cleanup")           _run_task "Full Cleanup"             full_cleanup ;;
                "0 - Exit"|"exit")            log_info "Returning to main menu."; return 0 ;;
                *)                             log_warn "Unknown task: $task"; continue ;;
            esac
            ran_any=1
        done <<< "$selections"

        if (( ran_any )); then
            local after_kb after_pct
            after_kb=$(_disk_used_kb)
            after_pct=$(_disk_used_pct)
            _print_summary "$before_kb" "$after_kb" "$before_pct" "$after_pct"
            echo
            log_success "Maintenance completed."
        fi
        prompt_continue
    done
}
