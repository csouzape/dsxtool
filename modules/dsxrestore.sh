#!/usr/bin/env bash
set -euo pipefail
# modules/dsxrestore.sh
# Intelligent backup/restore manager for dotfiles, configs, and other important files.
# Features planned:
# - Backup and restore functionality for dotfiles and configs.
# - Intelligent detection of changes in dotfiles and configs.
# - Integration with version control systems (e.g., Git) for tracking changes.
# - App snapshot
# - restore functionality for installed applications and their configurations.

readonly DSX_BACKUP_ROOT="${DSX_BACKUP_ROOT:-$HOME/.local/share/dsxtool/backups}"
readonly DSX_BACKUP_MIN_SPACE_KB="${DSX_BACKUP_MIN_SPACE_KB:-512000}"

check_dependencies() {
  local dependencies=("git" "unzip" "fzf" "tar" "pv")
  for dep in "${dependencies[@]}"; do
    log_info "Checking dependency: $dep"
    if ! command -v "$dep" &>/dev/null; then
      log_warn "$dep not found. Installing..."
      if pkg_install "$dep"; then
        log_info "$dep installed successfully."
      else
        log_error "Failed to install $dep."
        return 1
      fi
    else
      log_info "$dep already installed. ($(command -v "$dep"))."
    fi
  done
}

backup_folder() {
  local -a candidates=()
  local -a found=()

  candidates+=("$HOME/.config")

  if command -v xdg-user-dir &>/dev/null; then
    local xdg_keys=("DESKTOP" "DOWNLOAD" "DOCUMENTS" "PICTURES" "MUSIC" "VIDEOS" "PUBLICSHARE" "TEMPLATES")
    local key dir dir_normalized home_normalized
    home_normalized="${HOME%/}"
    for key in "${xdg_keys[@]}"; do
      dir=$(xdg-user-dir "$key" 2>/dev/null)
      dir_normalized="${dir%/}"
      [[ -n "$dir_normalized" && "$dir_normalized" != "$home_normalized" ]] && candidates+=("$dir_normalized")
    done
  else
    log_warn "xdg-user-dir not found, falling back to common EN/PT-BR paths" >&2
    candidates+=(
      "$HOME/Downloads" "$HOME/Documents" "$HOME/Documentos"
      "$HOME/Pictures" "$HOME/Imagens"
      "$HOME/Music" "$HOME/Músicas"
      "$HOME/Videos" "$HOME/Vídeos"
    )
  fi

  local seen=()
  for folder in "${candidates[@]}"; do
    [[ -d "$folder" ]] || continue

    if [[ "$folder" != /* ]]; then
      log_warn "Skipping non-absolute candidate: $folder" >&2
      continue
    fi
    if [[ ! " ${seen[*]} " =~ " ${folder} " ]]; then
      seen+=("$folder")
      found+=("$folder")
      log_info "Found: $folder" >&2
    fi
  done

  if [[ ${#found[@]} -eq 0 ]]; then
    log_error "No target folders found on the system." >&2
    return 1
  fi

  printf '%s\n' "${found[@]}"
  return 0
}

select_backup_targets() {
  local -a candidates=()
  mapfile -t candidates < <(backup_folder) || return 1
  candidates+=("Exit")

  local -a selected=()
  if ! mapfile -t selected < <(
    printf '%s\n' "${candidates[@]}" |
      fzf --multi \
        --layout=reverse \
        --prompt="Select what to include in the backup > " \
        --header="TAB to mark multiple | ENTER to confirm | select Exit to cancel" \
        --preview='du -sh {} 2>/dev/null'
  ); then
    log_warn "Backup selection cancelled." >&2
    return 1
  fi

  if [[ ${#selected[@]} -eq 0 ]]; then
    log_warn "Nothing selected. Backup aborted." >&2
    return 1
  fi

  local item
  for item in "${selected[@]}"; do
    if [[ "$item" == "Exit" ]]; then
      log_info "Exit selected. Backup aborted." >&2
      return 1
    fi
  done

  printf '%s\n' "${selected[@]}"
  return 0
}

prepare_backup_destination() {
  if [[ ! -d "$DSX_BACKUP_ROOT" ]]; then
    log_warn "Backup directory doesn't exist, creating: $DSX_BACKUP_ROOT"
    mkdir -p "$DSX_BACKUP_ROOT" || {
      log_error "Couldn't create $DSX_BACKUP_ROOT"
      return 1
    }
  fi

  if [[ ! -w "$DSX_BACKUP_ROOT" ]]; then
    log_error "No write permission on $DSX_BACKUP_ROOT"
    return 1
  fi

  local available_kb
  available_kb=$(df --output=avail "$DSX_BACKUP_ROOT" | tail -n1 | tr -d ' ')
  if ((available_kb < DSX_BACKUP_MIN_SPACE_KB)); then
    log_error "Not enough space on $DSX_BACKUP_ROOT (${available_kb}KB available, ${DSX_BACKUP_MIN_SPACE_KB}KB required)"
    return 1
  fi

  return 0
}

create_backup() {
  clear
  local -a targets=("$@")
  if [[ ${#targets[@]} -eq 0 ]]; then
    log_error "create_backup called with no targets."
    return 1
  fi

  local -a valid_targets=()
  local target
  for target in "${targets[@]}"; do
    if [[ "$target" != /* ]]; then
      log_warn "Skipping non-absolute target: $target"
      continue
    fi
    if [[ ! -e "$target" ]]; then
      log_warn "Skipping missing target (may have been removed): $target"
      continue
    fi
    valid_targets+=("$target")
  done

  if [[ ${#valid_targets[@]} -eq 0 ]]; then
    log_error "No valid targets remain; aborting backup."
    return 1
  fi

  local timestamp archive_name archive_path
  timestamp=$(date +%Y%m%d-%H%M%S)
  archive_name="dsxbackup_${timestamp}.tar.gz"
  archive_path="${DSX_BACKUP_ROOT}/${archive_name}"

  local total_bytes estimated_size
  total_bytes=$(du -sbc "${valid_targets[@]}" 2>/dev/null | tail -n1 | cut -f1)
  estimated_size=$(numfmt --to=iec --suffix=B "${total_bytes:-0}" 2>/dev/null || echo "unknown")

  log_info "Building archive: $archive_name"
  log_info "Targets: ${valid_targets[*]}"
  log_info "Estimated size: ${estimated_size} (compression may take a while, please wait)"

  local -a tar_args=()
  for target in "${valid_targets[@]}"; do
    tar_args+=("-C" "$(dirname -- "$target")" "$(basename -- "$target")")
  done

  if tar -cf - \
    --ignore-failed-read \
    "${tar_args[@]}" |
    pv -f -s "${total_bytes:-0}" -N "Archiving" |
    gzip >"$archive_path"; then
    local size
    size=$(du -sh "$archive_path" | cut -f1)
    log_info "Backup done: $archive_path ($size)"
  else
    log_error "tar failed, backup is incomplete."
    rm -f "$archive_path"
    return 1
  fi

  return 0
}

# ── App snapshot: package lists ──────────────────────────────────────

get_pacman_explicit(){
    pacman -Qqen 2>/dev/null
}

get_pacman_foreign(){
    pacman -Qqem 2>/dev/null
}

get_flatpak_apps(){
    if command -v flatpak &> /dev/null; then
        flatpak list --app --columns=application 2>/dev/null
    fi
}

get_base_group_packages(){
    pacman -Qqg base base-devel 2>/dev/null
}

filter_user_packages(){
    local -a base_pkgs=()
    mapfile -t base_pkgs < <(get_base_group_packages)

    local exclude_file="${DSX_EXCLUDE_PATTERNS_FILE:-$HOME/.config/dsxtool/app-snapshot-exclude.txt}"
    local -a patterns=()
    if [[ -f "$exclude_file" ]]; then
        mapfile -t patterns < <(grep -vE '^\s*(#|$)' "$exclude_file")
    else
        patterns=(
            '^linux-.*'
            '.*-firmware$'
            '^mesa'
            '^lib32-.*'
            '^vulkan-.*'
            '^opencl-.*'
            '^(intel|amd|nvidia)-.*'
            '^xf86-(video|input)-.*'
            '^cachyos-.*'
            '^systemd.*'
            '^networkmanager.*'
            '^pipewire.*'
            '^wireplumber$'
            '^bluez.*'
            '^sof-firmware$'
            '^plymouth$'
            '^(grub|efibootmgr|mkinitcpio).*'
        )
    fi

    local pkg is_system sp pattern
    while IFS= read -r pkg; do
        [[ -z "$pkg" ]] && continue
        is_system=0

        for sp in "${base_pkgs[@]}"; do
            [[ "$pkg" == "$sp" ]] && { is_system=1; break; }
        done

        if [[ $is_system -eq 0 ]]; then
            for pattern in "${patterns[@]}"; do
                [[ "$pkg" =~ $pattern ]] && { is_system=1; break; }
            done
        fi

        [[ $is_system -eq 0 ]] && printf '%s\n' "$pkg"
    done
}

create_app_snapshot(){
    prepare_backup_destination || return 1

    local timestamp snapshot_dir
    timestamp=$(date +%Y%m%d-%H%M%S)
    snapshot_dir="${DSX_BACKUP_ROOT}/app-snapshot-${timestamp}"

    mkdir -p "$snapshot_dir" || { log_error "Couldn't create $snapshot_dir"; return 1; }

    log_info "Capturing installed package lists..."

    local pacman_count=0 foreign_count=0 flatpak_count=0

    get_pacman_explicit | filter_user_packages > "${snapshot_dir}/pacman-explicit.txt"
    pacman_count=$(wc -l < "${snapshot_dir}/pacman-explicit.txt")
    log_info "User-installed packages (filtered): $pacman_count"

    get_pacman_foreign > "${snapshot_dir}/pacman-foreign.txt"
    foreign_count=$(wc -l < "${snapshot_dir}/pacman-foreign.txt")
    log_info "AUR/foreign packages: $foreign_count"

    if get_flatpak_apps > "${snapshot_dir}/flatpak-apps.txt" && [[ -s "${snapshot_dir}/flatpak-apps.txt" ]]; then
        flatpak_count=$(wc -l < "${snapshot_dir}/flatpak-apps.txt")
        log_info "Flatpak apps: $flatpak_count"
    else
        rm -f "${snapshot_dir}/flatpak-apps.txt"
        log_info "Flatpak not found or no apps installed, skipping."
    fi

    [[ -f /etc/pacman.conf ]] && cp /etc/pacman.conf "${snapshot_dir}/pacman.conf"

    {
        echo "Snapshot taken: $(date)"
        echo "Host: $(hostname)"
        echo "Official packages: $pacman_count"
        echo "AUR/foreign packages: $foreign_count"
        echo "Flatpak apps: $flatpak_count"
    } > "${snapshot_dir}/snapshot-info.txt"

    local archive_name="dsxappsnapshot_${timestamp}.tar.gz"
    local archive_path="${DSX_BACKUP_ROOT}/${archive_name}"

    if tar -czf "$archive_path" -C "$DSX_BACKUP_ROOT" "app-snapshot-${timestamp}"; then
        rm -rf "$snapshot_dir"
        local size
        size=$(du -sh "$archive_path" | cut -f1)
        log_info "App snapshot done: $archive_path ($size)"
    else
        log_error "Failed to archive app snapshot."
        rm -rf "$snapshot_dir"
        return 1
    fi

    return 0
}


find_app_snapshots(){
    local -a search_roots=("/")
    local -a prune_paths=(
        "/proc" "/sys" "/dev" "/run" "/tmp"
        "/var/tmp" "/var/cache" "/var/lib/docker"
        "/snap" "/nix"
    )

    local -a prune_args=()
    local p
    for p in "${prune_paths[@]}"; do
        prune_args+=(-path "$p" -o)
    done

    unset 'prune_args[${#prune_args[@]}-1]'

    find "${search_roots[@]}" \
        \( "${prune_args[@]}" \) -prune -o \
        -type f -name 'dsxappsnapshot_*.tar.gz' -print 2>/dev/null \
        | sort -r
}

create_app_snapshot(){
    prepare_backup_destination || return 1

    local timestamp snapshot_dir
    timestamp=$(date +%Y%m%d-%H%M%S)
    snapshot_dir="${DSX_BACKUP_ROOT}/app-snapshot-${timestamp}"

    mkdir -p "$snapshot_dir" || { log_error "Couldn't create $snapshot_dir"; return 1; }

    log_info "Capturing installed package lists..."

    local pacman_count=0 foreign_count=0 flatpak_count=0

    get_pacman_explicit | filter_user_packages > "${snapshot_dir}/pacman-explicit.txt"
    pacman_count=$(wc -l < "${snapshot_dir}/pacman-explicit.txt")
    log_info "User-installed packages (filtered): $pacman_count"

    get_pacman_foreign > "${snapshot_dir}/pacman-foreign.txt"
    foreign_count=$(wc -l < "${snapshot_dir}/pacman-foreign.txt")
    log_info "AUR/foreign packages: $foreign_count"

    if get_flatpak_apps > "${snapshot_dir}/flatpak-apps.txt" && [[ -s "${snapshot_dir}/flatpak-apps.txt" ]]; then
        flatpak_count=$(wc -l < "${snapshot_dir}/flatpak-apps.txt")
        log_info "Flatpak apps: $flatpak_count"
    else
        rm -f "${snapshot_dir}/flatpak-apps.txt"
        log_info "Flatpak not found or no apps installed, skipping."
    fi

    [[ -f /etc/pacman.conf ]] && cp /etc/pacman.conf "${snapshot_dir}/pacman.conf"

    {
        echo "Snapshot taken: $(date)"
        echo "Host: $(hostname)"
        echo "Official packages: $pacman_count"
        echo "AUR/foreign packages: $foreign_count"
        echo "Flatpak apps: $flatpak_count"
    } > "${snapshot_dir}/snapshot-info.txt"

    local archive_name="dsxappsnapshot_${timestamp}.tar.gz"
    local archive_path="${DSX_BACKUP_ROOT}/${archive_name}"

    if tar -czf "$archive_path" -C "$DSX_BACKUP_ROOT" "app-snapshot-${timestamp}"; then
        rm -rf "$snapshot_dir"
        local size
        size=$(du -sh "$archive_path" | cut -f1)
        log_info "App snapshot done: $archive_path ($size)"
    else
        log_error "Failed to archive app snapshot."
        rm -rf "$snapshot_dir"
        return 1
    fi

    return 0
}

# ── App snapshot: restore ────────────────────────────────────────────

restore_app_snapshot(){
    local archive="$1"

    if [[ -z "$archive" || ! -f "$archive" ]]; then
        log_error "Snapshot archive not found: $archive"
        return 1
    fi

    local restore_dir
    restore_dir=$(mktemp -d) || { log_error "Couldn't create temp dir."; return 1; }

    if ! tar -xzf "$archive" -C "$restore_dir" --strip-components=1; then
        log_error "Failed to extract snapshot archive."
        rm -rf "$restore_dir"
        return 1
    fi

    if [[ -f "${restore_dir}/snapshot-info.txt" ]]; then
        log_info "Restoring snapshot:"
        cat "${restore_dir}/snapshot-info.txt"
    fi

    if [[ -s "${restore_dir}/pacman-explicit.txt" ]]; then
        log_info "Installing official packages via pacman..."
        if ! sudo pacman -S --needed - < "${restore_dir}/pacman-explicit.txt"; then
            log_warn "Some official packages failed to install. Check the log."
        fi
    fi

    if [[ -s "${restore_dir}/pacman-foreign.txt" ]]; then
        local aur_helper=""
        for helper in yay paru; do
            command -v "$helper" &> /dev/null && { aur_helper="$helper"; break; }
        done

        if [[ -n "$aur_helper" ]]; then
            log_info "Installing AUR packages via $aur_helper..."
            if ! "$aur_helper" -S --needed - < "${restore_dir}/pacman-foreign.txt"; then
                log_warn "Some AUR packages failed to install. Check the log."
            fi
        else
            log_warn "No AUR helper (yay/paru) found. Skipping AUR packages:"
            cat "${restore_dir}/pacman-foreign.txt"
        fi
    fi

    if [[ -s "${restore_dir}/flatpak-apps.txt" ]] && command -v flatpak &> /dev/null; then
        log_info "Installing Flatpak apps..."
        while IFS= read -r app_id; do
            [[ -z "$app_id" ]] && continue
            flatpak install -y flathub "$app_id" || log_warn "Failed to install Flatpak app: $app_id"
        done < "${restore_dir}/flatpak-apps.txt"
    fi

    rm -rf "$restore_dir"
    log_info "App snapshot restore complete."
    return 0
}

# ── App snapshot: cleanup ────────────────────────────────────────────

clean_app_snapshots(){
    local FZF_COLORS="bg:#121212,bg+:#1e1e1e,fg:#d1d1d1,fg+:#ffffff,hl:#89b4fa,hl+:#89b4fa,prompt:#cba6f7,pointer:#f38ba8,marker:#a6e3a1,header:#e8e8e8,border:#313244"

    log_info "Searching the system for app snapshots (this may take a moment)..."
    local -a archives=()
    mapfile -t archives < <(find_app_snapshots)

    if [[ ${#archives[@]} -eq 0 ]]; then
        log_warn "No app snapshots found on the system."
        return 0
    fi

    local mode
    if ! mode=$(printf '%s\n' "Select manually" "Keep only N most recent" "Delete all" "Cancel" | fzf \
        --layout=reverse \
        --prompt="Clean app snapshots > " \
        --color="$FZF_COLORS" \
        --header="Found ${#archives[@]} snapshot(s) | Enter to select, Ctrl-C to cancel" \
        --border=rounded \
        --pointer="▶" \
        --info=inline); then
        log_info "Cleanup cancelled."
        return 0
    fi

    local -a to_delete=()
    case "$mode" in
        "Select manually")
            if ! mapfile -t to_delete < <(
                printf '%s\n' "${archives[@]}" | fzf --multi \
                  --layout=reverse \
                  --prompt="Select snapshots to delete > " \
                  --color="$FZF_COLORS" \
                  --header="TAB to mark multiple | ENTER to confirm | ESC/Ctrl-C to cancel" \
                  --preview='tar -xzOf {} --wildcards "*/snapshot-info.txt" 2>/dev/null; echo; echo "Size: $(du -sh {} 2>/dev/null | cut -f1)"' \
                  --preview-window=right:50%:wrap,border-left \
                  --border=rounded \
                  --pointer="▶" \
                  --marker="✔" \
                  --info=inline
            ); then
                log_info "Cleanup cancelled."
                return 0
            fi
            ;;
        "Keep only N most recent")
            local keep
            read -rp "How many recent snapshots to keep? " keep < /dev/tty
            if [[ ! "$keep" =~ ^[0-9]+$ ]]; then
                log_error "Invalid number: $keep"
                return 1
            fi

            if (( keep >= ${#archives[@]} )); then
                log_info "Nothing to remove ($keep >= ${#archives[@]} snapshots found)."
                return 0
            fi
            to_delete=("${archives[@]:$keep}")
            ;;
        "Delete all")
            to_delete=("${archives[@]}")
            ;;
        "Cancel"|"")
            log_info "Cleanup cancelled."
            return 0
            ;;
    esac

    if [[ ${#to_delete[@]} -eq 0 ]]; then
        log_warn "Nothing selected. Cleanup aborted."
        return 0
    fi

    log_warn "The following snapshot(s) will be permanently deleted:"
    printf '  %s\n' "${to_delete[@]}"

    local confirm
    read -rp "Confirm deletion? [y/N] " confirm < /dev/tty
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        log_info "Cleanup cancelled."
        return 0
    fi

    local archive freed_kb=0 size_kb
    for archive in "${to_delete[@]}"; do
        if [[ -f "$archive" ]]; then
            size_kb=$(du -k "$archive" 2>/dev/null | cut -f1)
            if rm -f "$archive"; then
                log_info "Deleted: $archive"
                freed_kb=$((freed_kb + ${size_kb:-0}))
            else
                log_warn "Failed to delete: $archive"
            fi
        fi
    done

    log_info "Cleanup complete. Freed: $(numfmt --to=iec --suffix=B $((freed_kb * 1024)) 2>/dev/null || echo "${freed_kb}KB")"
    return 0
}

if [[ -z "${BANNER:-}" ]]; then
  readonly BANNER=$(
    cat <<'EOF'
██████╗ ███████╗██╗  ██╗██████╗ ███████╗███████╗████████╗ ██████╗ ██████╗ ███████╗
██╔══██╗██╔════╝╚██╗██╔╝██╔══██╗██╔════╝██╔════╝╚══██╔══╝██╔═══██╗██╔══██╗██╔════╝
██║  ██║███████╗ ╚███╔╝ ██████╔╝█████╗  ███████╗   ██║   ██║   ██║██████╔╝█████╗
██║  ██║╚════██║ ██╔██╗ ██╔══██╗██╔══╝  ╚════██║   ██║   ██║   ██║██╔══██╗██╔══╝
██████╔╝███████║██╔╝ ██╗██║  ██║███████╗███████║   ██║   ╚██████╔╝██║  ██║███████╗
╚═════╝ ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚══════╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚══════╝
EOF
  )
fi

main(){
    clear
    check_dependencies || return 1

    local USER_NAME
    USER_NAME="${SUDO_USER:-$USER}"
    local FZF_COLORS="bg:#121212,bg+:#1e1e1e,fg:#d1d1d1,fg+:#ffffff,hl:#89b4fa,hl+:#89b4fa,prompt:#cba6f7,pointer:#f38ba8,marker:#a6e3a1,header:#e8e8e8,border:#313244"
    local choice
    if ! choice=$(printf '%s\n' "Create backup" "App snapshot" "Restore app snapshot"  "Clean app snapshots" "Exit" | fzf \
        --layout=reverse \
        --prompt="DSXRestore > " \
        --color="$FZF_COLORS" \
        --header="$BANNER

  user: $USER_NAME
  destination: $DSX_BACKUP_ROOT
  ─────────────────────────────────────────────
  Enter to select, Ctrl-C to cancel." \
        --preview='
            case {} in
                "Create backup")
                    echo "Scan .config and XDG user folders (Downloads, Pictures, Documents, etc), let you pick which ones to include, and pack them into a timestamped tar.gz under '"$DSX_BACKUP_ROOT"'."
                    ;;
                "App snapshot")
                    echo "Capture the list of installed packages (pacman, AUR/foreign, Flatpak) plus pacman.conf into a small tar.gz under '"$DSX_BACKUP_ROOT"'. Lightweight and portable — no binaries or configs, just what to reinstall."
                    ;;
                "Restore app snapshot")
                    echo "Pick a previously created app-snapshot archive and reinstall its packages: official via pacman, AUR via yay/paru (if installed), and Flatpak apps via flathub."
                    ;;
                "Clean app snapshots")
                    echo "Remove old app-snapshot archives: pick manually, keep only the N most recent, or wipe them all. Asks for confirmation before deleting."
                    ;;
                "Exit")
                    echo "Quit DSXRestore."
                    ;;
            esac
        ' \
        --preview-window=right:50%:wrap,border-left \
        --border=rounded \
        --pointer="▶" \
        --info=inline); then
        log_info "Exiting DSXRestore."
        return 0
    fi

    case "$choice" in
        "Create backup")
            prepare_backup_destination || return 1
            local -a targets=()
            mapfile -t targets < <(select_backup_targets) || return 1
            create_backup "${targets[@]}" || return 1
            ;;
        "App snapshot")
            create_app_snapshot || return 1
            ;;
        "Restore app snapshot")
            log_info "Searching the system for app snapshots (this may take a moment)..."
            local -a archives=()
            mapfile -t archives < <(find_app_snapshots)

             if [[ ${#archives[@]} -eq 0 ]]; then
                    log_warn "No app snapshots found on the system."
                    return 0
             fi

             local selected_archive
            if ! selected_archive=$(printf '%s\n' "${archives[@]}" | fzf \
              --layout=reverse \
              --prompt="Select snapshot to restore > " \
              --color="$FZF_COLORS" \
              --header="Enter to select, Ctrl-C to cancel" \
              --preview='tar -xzOf {} --wildcards "*/snapshot-info.txt" 2>/dev/null' \
              --preview-window=right:50%:wrap,border-left \
              --border=rounded \
              --pointer="▶" \
              --info=inline); then
                  log_info "Restore cancelled."
                  return 0
           fi

            [[ -z "$selected_archive" ]] && { log_info "Restore cancelled."; return 0; }

            restore_app_snapshot "$selected_archive" || return 1
            ;;
        "Clean app snapshots")
            clean_app_snapshots || return 1
            ;;
        "Exit"|"")
            log_info "Exiting DSXRestore."
            return 0
            ;;
    esac
}
