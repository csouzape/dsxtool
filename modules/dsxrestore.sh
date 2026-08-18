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
    local dependencies=("git" "unzip" "fzf" "tar")
    for dep in "${dependencies[@]}"; do
        log_info "Checking dependency: $dep"
        if ! command -v "$dep" &> /dev/null; then
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

backup_folder(){
    local -a candidates=()
    local -a found=()

    candidates+=("$HOME/.config")

    if command -v xdg-user-dir &> /dev/null; then
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
            "$HOME/Pictures"  "$HOME/Imagens"
            "$HOME/Music"     "$HOME/Músicas"
            "$HOME/Videos"    "$HOME/Vídeos"
        )
    fi

    local seen=()
    for folder in "${candidates[@]}"; do
        [[ -d "$folder" ]] || continue
        # Only accept absolute paths: create_backup relies on this invariant
        # when stripping the leading "/" for tar's -C / usage.
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

select_backup_targets(){
    local -a candidates=()
    mapfile -t candidates < <(backup_folder) || return 1
    candidates+=("Exit")

    local -a selected=()
    # Capture fzf output safely without breaking pipefail if the user cancels (ESC)
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

prepare_backup_destination(){
    if [[ ! -d "$DSX_BACKUP_ROOT" ]]; then
        log_warn "Backup directory doesn't exist, creating: $DSX_BACKUP_ROOT"
        mkdir -p "$DSX_BACKUP_ROOT" || { log_error "Couldn't create $DSX_BACKUP_ROOT"; return 1; }
    fi

    if [[ ! -w "$DSX_BACKUP_ROOT" ]]; then
        log_error "No write permission on $DSX_BACKUP_ROOT"
        return 1
    fi

    local available_kb
    available_kb=$(df --output=avail "$DSX_BACKUP_ROOT" | tail -n1 | tr -d ' ')
    if (( available_kb < DSX_BACKUP_MIN_SPACE_KB )); then
        log_error "Not enough space on $DSX_BACKUP_ROOT (${available_kb}KB available, ${DSX_BACKUP_MIN_SPACE_KB}KB required)"
        return 1
    fi

    return 0
}

create_backup(){
    local -a targets=("$@")
    if [[ ${#targets[@]} -eq 0 ]]; then
        log_error "create_backup called with no targets."
        return 1
    fi

    # Re-validate targets right before archiving: they must exist, be absolute,
    # and still be present (selection and creation happen at different times).
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

    local estimated_size
    estimated_size=$(du -shc "${valid_targets[@]}" 2>/dev/null | tail -n1 | cut -f1)

    log_info "Building archive: $archive_name"
    log_info "Targets: ${valid_targets[*]}"
    log_info "Estimated uncompressed size: ${estimated_size:-unknown} (compression may take a while, please wait)"

    # GNU tar accepts multiple -C options: each one changes directory only for
    # the arguments that follow it. Using a per-target "-C <parent> <basename>"
    # pair means the archive stores just the selected folder (e.g. "Imagens/...")
    # instead of the full absolute path ("home/carlos/Imagens/...").
    local -a tar_args=()
    for target in "${valid_targets[@]}"; do
        tar_args+=("-C" "$(dirname -- "$target")" "$(basename -- "$target")")
    done

    # --checkpoint prints a dot-style progress marker every N blocks so a large
    # or slow (e.g. gzip on weak CPUs) archive doesn't look like it's hung.
    if tar -czf "$archive_path" \
        --ignore-failed-read \
        --checkpoint=200 \
        --checkpoint-action=echo="Archiving... %u files" \
        "${tar_args[@]}"; then
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

# Guarded so this module can be safely sourced more than once
# (e.g. when the parent menu reloads modules) without a
# "readonly variable" error killing the whole tool.
if [[ -z "${BANNER:-}" ]]; then
    readonly BANNER=$(cat <<'EOF'
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
    check_dependencies || return 1

    local USER_NAME
    USER_NAME="${SUDO_USER:-$USER}"

    local FZF_COLORS="bg:#121212,bg+:#1e1e1e,fg:#d1d1d1,fg+:#ffffff,hl:#89b4fa,hl+:#89b4fa,prompt:#cba6f7,pointer:#f38ba8,marker:#a6e3a1,header:#e8e8e8,border:#313244"

    local choice
    # Guard the main fzf call to avoid crashing if the user cancels with ESC
    if ! choice=$(printf '%s\n' "Create backup" "Exit" | fzf \
        --layout=reverse \
        --prompt="DSXRestore > " \
        --color="$FZF_COLORS" \
        --header="$BANNER

  user: $USER_NAME
  destination: $DSX_BACKUP_ROOT
  ─────────────────────────────────────────────
  Enter to select, Ctrl-C to cancel." \
        --preview="echo 'Scan .config and XDG user folders (Downloads, Pictures, Documents, etc), let you pick which ones to include, and pack them into a timestamped tar.gz under $DSX_BACKUP_ROOT.'" \
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
        "Exit"|"")
            log_info "Exiting DSXRestore."
            return 0
            ;;
    esac
}
