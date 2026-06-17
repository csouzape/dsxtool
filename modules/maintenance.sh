#!/usr/bin/env bash
set -uo pipefail

# ---------------------------------------------------------------------------
# dsxtool · System Maintenance module
# ---------------------------------------------------------------------------
# Provides a consolidated, explicit and colorful maintenance menu with live
# disk usage tracking. Every cleanup step reports how much space it freed and
# a final summary shows the percentage "profit" gained on the main disk (/).
# ---------------------------------------------------------------------------

# --- Colors (defined locally so the module is safe even if sourced alone) ---
RED=$'\033[0;31m';   GREEN=$'\033[0;32m';  YELLOW=$'\033[1;33m'
BLUE=$'\033[0;34m';  CYAN=$'\033[0;36m';   MAGENTA=$'\033[0;35m'
BOLD=$'\033[1m';     DIM=$'\033[2m';       RESET=$'\033[0m'

# --- Extended logging helpers (complement core/common.sh) ------------------
log_step()    { echo -e "${CYAN}${BOLD}[STEP]${RESET} $*"; }
log_success() { echo -e "${GREEN}${BOLD}[ OK ]${RESET} $*"; }
log_skip()    { echo -e "${DIM}[SKIP] $*${RESET}"; }

_section() {
    echo
    echo -e "${MAGENTA}${BOLD}━━━━━ $* ━━━━━${RESET}"
}

# --- fzf helper (avoids fzf reading the parent stdin) ----------------------
_fzf_menu() {
    local tmp_in tmp_out
    tmp_in=$(mktemp)
    tmp_out=$(mktemp)
    cat > "$tmp_in"
    fzf "$@" < "$tmp_in" > "$tmp_out" || true
    cat "$tmp_out"
    rm -f "$tmp_in" "$tmp_out"
}

# ---------------------------------------------------------------------------
# Disk usage helpers (all operate on the root filesystem "/")
# ---------------------------------------------------------------------------
_disk_used_pct() { df -P /  | awk 'NR==2{gsub(/%/,"",$5); print $5+0}'; }
_disk_used_kb()  { df -Pk / | awk 'NR==2{print $3+0}'; }
_disk_avail_kb() { df -Pk / | awk 'NR==2{print $4+0}'; }

# Human-readable size from a kilobyte value.
_fmt_kb() {
    awk -v k="${1:-0}" 'BEGIN{
        b = k * 1024; split("B KB MB GB TB PB", u, " "); i = 1;
        while (b >= 1024 && i < 6) { b /= 1024; i++ }
        printf("%.1f %s", b, u[i])
    }'
}

# Colored usage bar: _disk_bar <pct> <width>
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

# ---------------------------------------------------------------------------
# Maintenance tasks
# ---------------------------------------------------------------------------
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
    log_step "Removing temp files older than 7 days (/tmp, /var/tmp)..."
    sudo find /tmp     -mindepth 1 -xdev -atime +7 -delete 2>/dev/null || true
    sudo find /var/tmp -mindepth 1 -xdev -atime +7 -delete 2>/dev/null || true
    log_info "Old temporary files cleaned."
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

disk_report() {
    log_step "Filesystem usage:"
    df -hT -x tmpfs -x devtmpfs -x squashfs 2>/dev/null || df -h
    echo
    log_step "Top space users in your home directory:"
    du -h -d1 "$HOME" 2>/dev/null | sort -rh | head -n 11
    echo
    log_step "Largest known caches:"
    du -sh "$HOME/.cache" "$HOME/.local/share/Trash" 2>/dev/null || true
}

# Run every *safe* cleanup in sequence.
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
    _run_task "SSD Trim"          trim_ssd
}

# ---------------------------------------------------------------------------
# Task runner: measures disk delta around a single task and reports it.
# ---------------------------------------------------------------------------
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

# Final summary box: shows total reclaimed space and the percentage "profit".
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

# ---------------------------------------------------------------------------
# Banner & menu preview
# ---------------------------------------------------------------------------
BANNER=$(printf '\e[38;2;249;226;175m')
BANNER+=$(cat <<'EOF'
███╗   ███╗ █████╗ ██╗███╗   ██╗████████╗███████╗███╗   ██╗ █████╗ ███╗   ██╗ ██████╗███████╗
████╗ ████║██╔══██╗██║████╗  ██║╚══██╔══╝██╔════╝████╗  ██║██╔══██╗████╗  ██║██╔════╝██╔════╝
██╔████╔██║███████║██║██╔██╗ ██║   ██║   █████╗  ██╔██╗ ██║███████║██╔██╗ ██║██║     █████╗
██║╚██╔╝██║██╔══██║██║██║╚██╗██║   ██║   ██╔══╝  ██║╚██╗██║██╔══██║██║╚██╗██║██║     ██╔══╝
██║ ╚═╝ ██║██║  ██║██║██║ ╚████║   ██║   ███████╗██║ ╚████║██║  ██║██║ ╚████║╚██████╗███████╗
╚═╝     ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝   ╚═╝   ╚══════╝╚═╝  ╚═══╝╚═╝  ╚═══╝╚═╝  ╚═══╝ ╚═════╝╚══════╝

EOF
)
BANNER+=$(printf '\e[0m')

_maintenance_preview() {
    case "$1" in
        "1 - Update System")           echo "Updates all system packages using the distro package manager (pacman, apt, or dnf)." ;;
        "2 - Clean Package Cache")     echo "Removes old packages from the local cache, freeing disk space without affecting installed packages." ;;
        "3 - Remove Orphan Packages")  echo "Removes packages installed as dependencies that are no longer required by anything." ;;
        "4 - Clean Journal Logs")      echo "Vacuums old systemd journal logs, keeping the last 2 weeks and capping size at 200M." ;;
        "5 - Clean Coredumps")         echo "Deletes crash core dumps stored under /var/lib/systemd/coredump." ;;
        "6 - Clean User Cache")        echo "Cleans the current user ~/.cache directory by removing application temporary files." ;;
        "7 - Clean Thumbnail Cache")   echo "Removes cached image thumbnails stored under ~/.cache/thumbnails." ;;
        "8 - Empty Trash")             echo "Permanently empties the user trash (~/.local/share/Trash)." ;;
        "9 - Clean Temp Files")        echo "Removes files older than 7 days from /tmp and /var/tmp." ;;
        "10 - Clean Unused Flatpaks")  echo "Removes Flatpak runtimes and extensions not used by any installed application." ;;
        "11 - Prune Docker")           echo "Frees space by removing dangling/unused Docker images, containers and networks." ;;
        "12 - Trim SSD")               echo "Runs fstrim on all mounted file systems to optimize SSD performance and lifespan." ;;
        "13 - Check Failed Services")  echo "Lists all failed systemd services, useful for diagnosing system issues." ;;
        "14 - Disk Usage Report")      echo "Shows filesystem usage and the largest directories/caches in your home." ;;
        "15 - Full Cleanup")           echo "Runs every safe cleanup task in sequence and reports the total space reclaimed." ;;
        "16 - Exit")                   echo "Exits the maintenance menu and returns to the main menu." ;;
    esac
}
export -f _maintenance_preview

# ---------------------------------------------------------------------------
# Main menu loop
# ---------------------------------------------------------------------------
system_maintenance() {
    while true; do
        clear

        local selections fzf_header used_pct free_h bar
        used_pct=$(_disk_used_pct)
        free_h=$(_fmt_kb "$(_disk_avail_kb)")
        bar=$(_disk_bar "$used_pct" 24)

        fzf_header="$(printf '%b' "$BANNER\n\n${CYAN}${BOLD}Disk /${RESET}  $bar  ${BOLD}${used_pct}%${RESET} used  •  ${free_h} free\n\n[TAB] Select  [ENTER] Run  [ESC] Back")"

        selections=$(printf '%s\n' \
            "1 - Update System" \
            "2 - Clean Package Cache" \
            "3 - Remove Orphan Packages" \
            "4 - Clean Journal Logs" \
            "5 - Clean Coredumps" \
            "6 - Clean User Cache" \
            "7 - Clean Thumbnail Cache" \
            "8 - Empty Trash" \
            "9 - Clean Temp Files" \
            "10 - Clean Unused Flatpaks" \
            "11 - Prune Docker" \
            "12 - Trim SSD" \
            "13 - Check Failed Services" \
            "14 - Disk Usage Report" \
            "15 - Full Cleanup" \
            "16 - Exit" \
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

        # Snapshot disk state before running the selected tasks.
        local before_kb before_pct
        before_kb=$(_disk_used_kb)
        before_pct=$(_disk_used_pct)

        local ran_any=0
        while read -r task; do
            [[ -z "$task" ]] && continue
            case "$task" in
                "1 - Update System")          _run_task "Update System"          pkg_update ;;
                "2 - Clean Package Cache")    _run_task "Clean Package Cache"     pkg_clean_cache ;;
                "3 - Remove Orphan Packages") _run_task "Remove Orphan Packages"  pkg_remove_orphans ;;
                "4 - Clean Journal Logs")     _run_task "Clean Journal Logs"      clean_journal ;;
                "5 - Clean Coredumps")        _run_task "Clean Coredumps"         clean_coredumps ;;
                "6 - Clean User Cache")       _run_task "Clean User Cache"        clean_user_cache ;;
                "7 - Clean Thumbnail Cache")  _run_task "Clean Thumbnail Cache"   clean_thumbnails ;;
                "8 - Empty Trash")            _run_task "Empty Trash"             empty_trash ;;
                "9 - Clean Temp Files")       _run_task "Clean Temp Files"        clean_temp ;;
                "10 - Clean Unused Flatpaks") _run_task "Clean Unused Flatpaks"   clean_flatpak ;;
                "11 - Prune Docker")          _run_task "Prune Docker"            prune_docker ;;
                "12 - Trim SSD")              _run_task "Trim SSD"                trim_ssd ;;
                "13 - Check Failed Services") _run_task "Check Failed Services"   check_failed_services ;;
                "14 - Disk Usage Report")     _run_task "Disk Usage Report"       disk_report ;;
                "15 - Full Cleanup")          _run_task "Full Cleanup"            full_cleanup ;;
                "16 - Exit"|"exit")           log_info "Returning to main menu."; return 0 ;;
                *)                            log_warn "Unknown task: $task"; continue ;;
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
