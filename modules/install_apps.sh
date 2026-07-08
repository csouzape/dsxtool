#!/usr/bin/env bash
set -uo pipefail

declare -A APP_REGISTRY
declare -A APP_CATEGORY
declare -A APP_SELECTED_METHODS

register_app() {
    local app="$1"
    local category="$2"
    local entry="$3"
    APP_REGISTRY["$app"]="$entry"
    APP_CATEGORY["$app"]="$category"
}

register_category_apps() {
    local category="$1"
    shift

    local app entry
    while (($#)); do
        app="$1"
        entry="$2"
        shift 2
        register_app "$app" "$category" "$entry"
    done
}

register_category_apps "Browsers" \
    "Firefox" "pkg|firefox|org.mozilla.firefox|-" \
    "Chromium" "pkg|chromium|org.chromium.Chromium|-" \
    "Brave" "flatpak|-|com.brave.Browser|-" \
    "Zen Browser" "flatpak|-|app.zen_browser.zen|-" \
    "Google Chrome" "native|-|-|-" \
    "Helium Browser" "native|-|-|-" \
    "Opera" "native|-|-|-"

register_category_apps "Media" \
    "VLC" "pkg|vlc|org.videolan.VLC|-" \
    "Spotify" "flatpak|-|com.spotify.Client|-" \
    "Celluloid" "pkg|celluloid|io.github.celluloid_player.Celluloid|-" \
    "Rhythmbox" "pkg|rhythmbox|org.gnome.Rhythmbox3|-" \
    "OBS Studio" "pkg|obs-studio|com.obsproject.Studio|-" \
    "MPV" "pkg|mpv|-|-" \
    "Handbrake" "pkg|handbrake|fr.handbrake.ghb|-" \
    "Kdenlive" "pkg|kdenlive|org.kde.kdenlive|-" \
    "Synergy" "native|-|-|-" \
    "EasyEffects" "pkg|easyeffects|-|-;flatpak|-|com.github.wwmm.easyeffects|-;aur|-|-|easyeffects"

register_category_apps "Communication" \
    "Discord" "flatpak|-|com.discordapp.Discord|-" \
    "Telegram" "flatpak|-|org.telegram.desktop|-" \
    "Signal" "flatpak|-|org.signal.Signal|-" \
    "Slack" "flatpak|-|com.slack.Slack|-" \
    "Zoom" "flatpak|-|us.zoom.Zoom|-" \
    "Teams" "flatpak|-|com.microsoft.Teams|-" \
    "YouTube Music Desktop" "native|-|-|-"

register_category_apps "Productivity" \
    "LibreOffice" "pkg|libreoffice|org.libreoffice.LibreOffice|-" \
    "Obsidian" "flatpak|-|md.obsidian.Obsidian|-" \
    "Thunderbird" "pkg|thunderbird|org.mozilla.Thunderbird|-" \
    "Bitwarden" "flatpak|-|com.bitwarden.desktop|-" \
    "SyncThingy" "flatpak|-|com.github.zocker_160.SyncThingy|-" \
    "Syncthing Tray" "flatpak|-|io.github.martchus.syncthingtray|-" \
    "Flameshot" "pkg|flameshot|org.flameshot.Flameshot|-" \
    "GIMP" "pkg|gimp|org.gimp.GIMP|-" \
    "Inkscape" "pkg|inkscape|org.inkscape.Inkscape|-"

register_category_apps "Gaming" \
    "Steam" "pkg|steam|com.valvesoftware.Steam|-" \
    "Lutris" "pkg|lutris|net.lutris.Lutris|-" \
    "Heroic Games Launcher" "flatpak|-|com.heroicgameslauncher.hgl|-" \
    "ProtonUp-Qt" "flatpak|-|net.davidotek.pupgui2|-" \
    "MangoHud" "pkg|mangohud|-|-" \
    "Sober" "flatpak|-|org.vinegarhq.Sober|-" \
    "Bottles" "flatpak|-|com.usebottles.bottles|-"

register_category_apps "System Tools" \
    "Alacritty" "pkg|alacritty|-|-" \
    "Kitty" "pkg|kitty|-|-" \
    "Konsole" "pkg|konsole|-|-" \
    "Ghostty" "terminal|ghostty|-|-" \
    "htop" "pkg|htop|-|-" \
    "btop" "pkg|btop|-|-" \
    "ncdu" "pkg|ncdu|-|-" \
    "tree" "pkg|tree|-|-" \
    "tmux" "pkg|tmux|-|-" \
    "jq" "pkg|jq|-|-" \
    "bat" "pkg|bat|-|-" \
    "ripgrep" "pkg|ripgrep|-|-" \
    "fd" "native|-|-|-" \
    "neofetch" "pkg|neofetch|-|-" \
    "fastfetch" "pkg|fastfetch|-|-" \
    "net-tools" "pkg|net-tools|-|-" \
    "openssh" "native|-|-|-"

_fzf_menu() {
    local tmp_in tmp_out
    tmp_in=$(mktemp)
    tmp_out=$(mktemp)
    cat > "$tmp_in"
    fzf "$@" < "$tmp_in" > "$tmp_out" || true
    cat "$tmp_out"
    rm -f "$tmp_in" "$tmp_out"
}

_target_label() {
    local target="$1"
    local method pkg_name flatpak_id aur_pkg
    IFS='|' read -r method pkg_name flatpak_id aur_pkg <<< "$target"

    case "$method" in
        pkg)
            case "$DISTRO" in
                arch) printf 'Pacman (%s)' "$pkg_name" ;;
                debian) printf 'APT (%s)' "$pkg_name" ;;
                fedora) printf 'DNF (%s)' "$pkg_name" ;;
                *) printf 'Package (%s)' "$pkg_name" ;;
            esac
            ;;
        flatpak) printf 'Flatpak (%s)' "${flatpak_id:-$pkg_name}" ;;
        aur) printf 'AUR (%s)' "${aur_pkg:-$pkg_name}" ;;
        terminal) printf 'Terminal (%s)' "$pkg_name" ;;
        native) printf 'Native (%s)' "$pkg_name" ;;
        *) printf 'Unknown (%s)' "$target" ;;
    esac
}

_get_available_targets() {
    local entry="$1"
    local -a targets=()
    local target method pkg_name flatpak_id aur_pkg

    IFS=';' read -r -a targets <<< "$entry"

    for target in "${targets[@]}"; do
        [[ -z "${target//[[:space:]]/}" ]] && continue
        IFS='|' read -r method pkg_name flatpak_id aur_pkg <<< "$target"

        case "$method" in
            pkg|flatpak|terminal|native)
                printf '%s\n' "$target"
                ;;
            aur)
                if [[ "$DISTRO" == "arch" ]] && get_aur_helper >/dev/null 2>&1; then
                    printf '%s\n' "$target"
                fi
                ;;
        esac
    done
}

_can_use_flatpak() {
    command -v flatpak >/dev/null 2>&1
}

_select_install_target() {
    local app="$1"
    local entry="$2"
    local -a options=()
    local -a labels=()
    local target selection label
    local index=0

    mapfile -t options < <(_get_available_targets "$entry")

    if [[ ${#options[@]} -eq 0 ]]; then
        return 1
    fi

    if [[ ${#options[@]} -eq 1 ]]; then
        printf '%s\n' "${options[0]}"
        return 0
    fi

    for target in "${options[@]}"; do
        labels+=("$(_target_label "$target")")
    done

    selection=$(printf '%s\n' "${labels[@]}" \
        | _fzf_menu \
            --prompt="Install method for $app > " \
            --header="[ENTER] select" \
            --height=8 \
            --layout=reverse \
            --border=rounded \
            --no-info)

    [[ -z "$selection" ]] && return 1

    for index in "${!labels[@]}"; do
        label="${labels[$index]}"
        if [[ "$label" == "$selection" ]]; then
            printf '%s\n' "${options[$index]}"
            return 0
        fi
    done

    printf '%s\n' "${options[0]}"
}

_is_installed() {
    local app="$1"
    local entry="${APP_REGISTRY[$app]:-}"
    local -a targets=()
    local target method pkg_name flatpak_id aur_pkg

    IFS=';' read -r -a targets <<< "$entry"

    for target in "${targets[@]}"; do
        [[ -z "${target//[[:space:]]/}" ]] && continue
        IFS='|' read -r method pkg_name flatpak_id aur_pkg <<< "$target"

        case "$method" in
            pkg)
                case "$DISTRO" in
                    arch)   pacman -Q "$pkg_name" &>/dev/null ;;
                    debian) dpkg -s "$pkg_name" &>/dev/null ;;
                    fedora) rpm -q "$pkg_name" &>/dev/null ;;
                esac
                ;;
            flatpak)
                flatpak list --app 2>/dev/null | grep -q "$flatpak_id"
                ;;
            aur)
                pacman -Q "$aur_pkg" &>/dev/null
                ;;
            terminal)
                command -v "$pkg_name" &>/dev/null
                ;;
            native)
                case "$app" in
                    "Google Chrome") command -v google-chrome-stable &>/dev/null || command -v google-chrome &>/dev/null ;;
                    "Helium Browser") [[ -x /opt/helium/helium ]] || command -v helium &>/dev/null || command -v helium-browser &>/dev/null || command -v helium-browser-bin &>/dev/null ;;
                    "fd")            command -v fd &>/dev/null || command -v fdfind &>/dev/null ;;
                    "openssh")       command -v ssh &>/dev/null ;;
                    *)               return 1 ;;
                esac
                ;;
            *) return 1 ;;
        esac

        if [[ $? -eq 0 ]]; then
            return 0
        fi
    done

    return 1
}

_remove_app() {
    local app="$1"
    local entry="${APP_REGISTRY[$app]:-}"
    local selected_target="${APP_SELECTED_METHODS[$app]:-}"
    local -a targets=()
    local target method pkg_name flatpak_id aur_pkg

    if [[ -z "$selected_target" ]]; then
        IFS=';' read -r -a targets <<< "$entry"
        for target in "${targets[@]}"; do
            [[ -z "${target//[[:space:]]/}" ]] && continue
            IFS='|' read -r method pkg_name flatpak_id aur_pkg <<< "$target"
            case "$method" in
                pkg)
                    case "$DISTRO" in
                        arch)   pacman -Q "$pkg_name" &>/dev/null && selected_target="$target" && break ;;
                        debian) dpkg -s "$pkg_name" &>/dev/null && selected_target="$target" && break ;;
                        fedora) rpm -q "$pkg_name" &>/dev/null && selected_target="$target" && break ;;
                    esac
                    ;;
                flatpak)
                    flatpak list --app 2>/dev/null | grep -q "$flatpak_id" && selected_target="$target" && break
                    ;;
                aur)
                    pacman -Q "$aur_pkg" &>/dev/null && selected_target="$target" && break
                    ;;
                terminal)
                    command -v "$pkg_name" &>/dev/null && selected_target="$target" && break
                    ;;
                native)
                    case "$app" in
                        "Google Chrome") command -v google-chrome-stable &>/dev/null || command -v google-chrome &>/dev/null ;;
                        "Helium Browser") [[ -x /opt/helium/helium ]] || command -v helium &>/dev/null || command -v helium-browser &>/dev/null || command -v helium-browser-bin &>/dev/null ;;
                        "fd")            command -v fd &>/dev/null || command -v fdfind &>/dev/null ;;
                        "openssh")       command -v ssh &>/dev/null ;;
                        *)               false ;;
                    esac
                    if [[ $? -eq 0 ]]; then
                        selected_target="$target"
                        break
                    fi
                    ;;
            esac
        done
    fi

    IFS='|' read -r method pkg_name flatpak_id aur_pkg <<< "$selected_target"

    log_info "Removing $app..."

    case "$method" in
        pkg)
            case "$DISTRO" in
                arch)   sudo pacman -Rns --noconfirm "$pkg_name" ;;
                debian) sudo apt-get remove -y "$pkg_name" ;;
                fedora) sudo dnf remove -y "$pkg_name" ;;
            esac
            ;;
        flatpak)
            flatpak uninstall -y "$flatpak_id"
            ;;
        aur)
            sudo pacman -Rns --noconfirm "$aur_pkg"
            ;;
        terminal)
            case "$DISTRO" in
                arch)   sudo pacman -Rns --noconfirm "$pkg_name" ;;
                debian) sudo apt-get remove -y "$pkg_name" ;;
                fedora) sudo dnf remove -y "$pkg_name" ;;
            esac
            ;;
        native)
            case "$app" in
                "Google Chrome")
                    case "$DISTRO" in
                        arch)   sudo pacman -Rns --noconfirm google-chrome ;;
                        debian) sudo apt-get remove -y google-chrome-stable ;;
                        fedora) sudo dnf remove -y google-chrome-stable ;;
                    esac
                    ;;
                "Helium Browser")
                    sudo rm -f /opt/helium/helium /usr/local/bin/helium /usr/bin/helium 2>/dev/null || true
                    ;;
                "fd")
                    case "$DISTRO" in
                        arch)   sudo pacman -Rns --noconfirm fd ;;
                        debian) sudo apt-get remove -y fd-find ;;
                        fedora) sudo dnf remove -y fd-find ;;
                    esac
                    ;;
                "openssh")
                    case "$DISTRO" in
                        arch)   sudo pacman -Rns --noconfirm openssh ;;
                        debian) sudo apt-get remove -y openssh-client ;;
                        fedora) sudo dnf remove -y openssh ;;
                    esac
                    ;;
                *)
                    die "No removal handler defined for: $app"
                    ;;
            esac
            ;;
        *)
            die "Unknown method '$method' for $app."
            ;;
    esac

    log_info "$app removed successfully."
}

_install_app() {
    local app="$1"
    local entry="${APP_REGISTRY[$app]:-}"

    if [[ -z "$entry" ]]; then
        die "Unknown app: $app"
    fi

    if _is_installed "$app"; then
        log_warn "$app is already installed."
        read -rp "$(echo -e "${YELLOW}Would you like to remove it? [y/n]: ${RESET}")" answer < /dev/tty
        if [[ "$answer" =~ ^[Yy]$ ]]; then
            _remove_app "$app"
        else
            log_info "Skipping $app."
        fi
        return
    fi

    local selected_target
    selected_target=$(_select_install_target "$app" "$entry") || die "No install target available for $app."
    APP_SELECTED_METHODS["$app"]="$selected_target"

    local method pkg_name flatpak_id aur_pkg
    IFS='|' read -r method pkg_name flatpak_id aur_pkg <<< "$selected_target"

    log_info "Installing $app using $(_target_label "$selected_target")..."

    case "$method" in
        pkg)
            pkg_install "$pkg_name" || die "Failed to install $app."
            ;;
        flatpak)
            if ! command -v flatpak &>/dev/null; then
                log_warn "Flatpak not installed. Installing first..."
                pkg_install flatpak || die "Failed to install Flatpak."
                flatpak remote-add --if-not-exists flathub \
                    https://dl.flathub.org/repo/flathub.flatpakrepo
            fi
            flatpak install -y flathub "$flatpak_id" \
                || die "Failed to install $app via Flatpak."
            ;;
        aur)
            require_aur_helper
            aur_install "$aur_pkg" \
                || die "Failed to install $app via AUR."
            ;;
        terminal)
            _install_terminal_app "$app"
            ;;
        native)
            _install_native_app "$app"
            ;;
        *)
            die "Unknown install method '$method' for $app."
            ;;
    esac

    log_info "$app installed successfully."
}

_install_terminal_app() {
    local app="$1"
    case "$app" in
        "Ghostty")
            case "$DISTRO" in
                arch)
                    pkg_install ghostty || die "Failed to install Ghostty."
                    ;;
                debian)
                    log_info "Installing Ghostty via install script (ubuntu)..."
                    curl -fsSL https://raw.githubusercontent.com/mkasberg/ghostty-ubuntu/HEAD/install.sh \
                        | sudo bash \
                        || die "Failed to install Ghostty."
                    ;;
                fedora)
                    log_info "Enabling Ghostty COPR and installing..."
                    sudo dnf copr enable -y scottames/ghostty \
                        || die "Failed to enable Ghostty COPR."
                    pkg_install ghostty || die "Failed to install Ghostty."
                    ;;
                *)
                    die "Unsupported distro for Ghostty: $DISTRO"
                    ;;
            esac
            ;;
        "Alacritty")
            pkg_install alacritty || die "Failed to install Alacritty."
            read -rp "Install csouzape's Alacritty configuration? (y/n): " confirm < /dev/tty
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                _apply_alacritty_config
            else
                log_warn "Configuration skipped."
            fi
            ;;
        *)
            die "Unknown terminal app: $app"
            ;;
    esac
}

_apply_alacritty_config() {
    log_info "Applying csouzape's Alacritty configuration..."
    mkdir -p "$HOME/.config/alacritty"

    cat > "$HOME/.config/alacritty/alacritty.yml" << 'EOF'
window:
  opacity: 0.6

font:
  size: 12.0
  normal:
    family: JetBrains Mono
    style: Regular

colors:
  primary:
    background: '#0f0f0f'
EOF

    log_info "Configuration saved to ~/.config/alacritty/alacritty.yml"
}

_install_native_app() {
    local app="$1"
    case "$app" in
        "Google Chrome")
            case "$DISTRO" in
                arch)
                    require_aur_helper
                    aur_install google-chrome \
                        || die "Failed to install Google Chrome via AUR."
                    ;;
                debian)
                    log_info "Downloading Google Chrome (.deb)..."
                    wget --progress=bar:force \
                        "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb" \
                        -O /tmp/google-chrome.deb \
                        || die "Failed to download Google Chrome."
                    sudo dpkg -i /tmp/google-chrome.deb 2>/dev/null || true
                    sudo apt-get install -f -y \
                        || die "Failed to fix Google Chrome dependencies."
                    rm -f /tmp/google-chrome.deb
                    ;;
                fedora)
                    log_info "Downloading Google Chrome (.rpm)..."
                    wget --progress=bar:force \
                        "https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm" \
                        -O /tmp/google-chrome.rpm \
                        || die "Failed to download Google Chrome."
                    sudo dnf install -y /tmp/google-chrome.rpm \
                        || die "Failed to install Google Chrome."
                    rm -f /tmp/google-chrome.rpm
                    ;;
                *)
                    die "Unsupported distro for Google Chrome: $DISTRO"
                    ;;
            esac
            ;;
        "Helium Browser")
            local repo="imputnet/helium-linux"
            local download_url fallback_download_url install_dir binary_path launcher_path

            install_dir="/opt/helium"
            binary_path="$install_dir/helium"
            launcher_path="/usr/local/bin/helium"
            fallback_download_url="https://github.com/imputnet/helium-linux/releases/download/0.14.3.1/helium-0.14.3.1-x86_64.AppImage"

            log_info "Installing Helium Browser..."

            if ! command -v jq &>/dev/null; then
                log_warn "jq not found. Installing it first..."
                pkg_install jq || die "Failed to install jq for Helium release detection."
            fi

            download_url=$(curl -fsSL "https://api.github.com/repos/$repo/releases/latest" \
                | jq -r '.assets[] | .browser_download_url' \
                | grep -iE 'helium-.*(x86_64|amd64).*\.appimage$' \
                | head -n 1) || die "Failed to retrieve latest Helium release."

            if [[ -z "$download_url" ]]; then
                log_warn "No x86_64 AppImage asset was found from the GitHub API; using the known fallback URL."
                download_url="$fallback_download_url"
            fi

            log_info "Helium download URL: $download_url"
            wget --progress=bar:force -O /tmp/helium.AppImage "$download_url" \
                || die "Failed to download Helium Browser."

            sudo mkdir -p "$install_dir"
            sudo install -m 0755 /tmp/helium.AppImage "$binary_path"
            sudo ln -sf "$binary_path" "$launcher_path"
            rm -f /tmp/helium.AppImage
            ;;
        "Opera")
            case "$DISTRO" in
                arch)
                    require_aur_helper
                    aur_install opera-bin \
                        || die "Failed to install Opera via AUR."
                    ;;
                debian)
                    log_info "Adding Opera APT repository..."
                    sudo install -d -m 0755 /etc/apt/keyrings
                    curl -fsSL https://deb.opera.com/archive.key \
                        | gpg --dearmor \
                        | sudo tee /etc/apt/keyrings/opera-browser.gpg > /dev/null \
                        || die "Failed to add Opera signing key."
                    echo "deb [signed-by=/etc/apt/keyrings/opera-browser.gpg] https://deb.opera.com/opera-stable/ stable non-free" \
                        | sudo tee /etc/apt/sources.list.d/opera-archive.list > /dev/null \
                        || die "Failed to add Opera apt source."
                    sudo apt-get update -y \
                        || die "Failed to update apt after adding Opera repository."
                    sudo apt-get install -y opera-stable \
                        || die "Failed to install Opera."
                    ;;
                fedora)
                    log_info "Adding Opera RPM repository..."
                    sudo rpm --import https://rpm.opera.com/rpmrepo.key 2>/dev/null || true
                    sudo tee /etc/yum.repos.d/opera.repo > /dev/null <<'EOF'
[opera]
name=Opera packages
type=rpm-md
baseurl=https://rpm.opera.com/rpm
gpgcheck=1
gpgkey=https://rpm.opera.com/rpmrepo.key
enabled=1
EOF
                    sudo dnf install -y opera-stable || sudo dnf install -y opera-developer \
                        || die "Failed to install Opera."
                    ;;
                *)
                    die "Unsupported distro for Opera: $DISTRO"
                    ;;
            esac
            ;;
        "fd")
            case "$DISTRO" in
                arch)   pkg_install fd ;;
                debian) pkg_install fd-find ;;
                fedora) pkg_install fd-find ;;
            esac
            ;;
        "openssh")
            case "$DISTRO" in
                arch)   pkg_install openssh ;;
                debian) pkg_install openssh-client ;;
                fedora) pkg_install openssh ;;
            esac
            ;;
        "YouTube Music Desktop")
            case "$DISTRO" in
                arch)
                    require_aur_helper
                    log_info "Checking if YouTube Music Desktop is installed..."
                    if ! aur_query ytmdesktop-bin; then
                        log_info "Installing YouTube Music Desktop from AUR..."
                        aur_install ytmdesktop-bin \
                            || die "Failed to install YouTube Music Desktop via AUR."
                    else
                        log_info "YouTube Music Desktop is already installed."
                    fi
                    ;;
                debian)
                    log_info "Downloading YouTube Music Desktop (.deb)..."
                    if ! command -v jq &>/dev/null; then
                        log_warn "jq not found. Installing it first..."
                        pkg_install jq || die "Failed to install jq for YouTube Music Desktop release detection."
                    fi

                    release_url="https://api.github.com/repos/ytmdesktop/ytmdesktop/releases/latest"
                    deb_url=$(curl -fsSL "$release_url" | jq -r '.assets[] | .browser_download_url' | grep -iE 'youtube-music-desktop-app.*\.deb$' | head -n 1) \
                        || die "Failed to retrieve latest YouTube Music Desktop DEB release."

                    if [[ -z "$deb_url" ]]; then
                        die "No suitable DEB asset found in the latest YouTube Music Desktop release."
                    fi

                    log_info "YouTube Music Desktop DEB URL: $deb_url"
                    wget --progress=bar:force -O /tmp/ytmdesktop.deb "$deb_url" \
                        || die "Failed to download YouTube Music Desktop."
                    sudo dpkg -i /tmp/ytmdesktop.deb 2>/dev/null || true
                    sudo apt-get install -f -y || die "Failed to fix YouTube Music Desktop dependencies."
                    rm -f /tmp/ytmdesktop.deb
                    ;;
                fedora)
                    log_info "Downloading YouTube Music Desktop (.rpm)..."
                    if ! command -v jq &>/dev/null; then
                        log_warn "jq not found. Installing it first..."
                        pkg_install jq || die "Failed to install jq for YouTube Music Desktop release detection."
                    fi

                    release_url="https://api.github.com/repos/ytmdesktop/ytmdesktop/releases/latest"
                    rpm_url=$(curl -fsSL "$release_url" | jq -r '.assets[] | .browser_download_url' | grep -iE 'youtube-music-desktop-app-.*\.x86_64\.rpm$' | head -n 1) \
                        || die "Failed to retrieve latest YouTube Music Desktop RPM release."

                    if [[ -z "$rpm_url" ]]; then
                        die "No suitable RPM asset found in the latest YouTube Music Desktop release."
                    fi

                    log_info "YouTube Music Desktop RPM URL: $rpm_url"
                    wget --progress=bar:force -O /tmp/ytmdesktop.rpm "$rpm_url" \
                        || die "Failed to download YouTube Music Desktop."
                    sudo dnf install -y /tmp/ytmdesktop.rpm \
                        || die "Failed to install YouTube Music Desktop."
                    rm -f /tmp/ytmdesktop.rpm
                    ;;
                *)
                    die "Unsupported distro for YouTube Music Desktop: $DISTRO"
                    ;;
            esac
            ;;
        "Synergy")
            case "$DISTRO" in
                arch)
                    if get_aur_helper >/dev/null 2>&1; then
                        log_info "Installing Synergy from AUR..."
                        aur_install synergy || die "Failed to install Synergy via AUR."
                    else
                        log_info "Downloading Synergy for Arch..."
                        wget --progress=bar:force "https://symless.com/synergy/download/package/synergy-personal-v3/arch-linux/synergy-3.6.1-linux-noble-x86_64.pkg.tar.zst" -O /tmp/synergy.pkg.tar.zst \
                            || die "Failed to download Synergy."

                        # detect if the download returned HTML (redirect/login page)
                        if file -b --mime-type /tmp/synergy.pkg.tar.zst | grep -q 'text/html'; then
                            cat /tmp/synergy.pkg.tar.zst | sed -n '1,120p'
                            rm -f /tmp/synergy.pkg.tar.zst
                            die "Downloaded file looks like HTML. Symless likely requires an authenticated download. Install 'yay' or 'paru' and try AUR, or provide a direct package URL."
                        fi

                        sudo pacman -U --noconfirm /tmp/synergy.pkg.tar.zst || die "Failed to install Synergy."
                        rm -f /tmp/synergy.pkg.tar.zst
                    fi
                    ;;
                debian)
                    log_info "Downloading Synergy (.deb)..."
                    wget --progress=bar:force "URL_DO_SYNERGY_DEB" -O /tmp/synergy.deb \
                        || die "Failed to download Synergy."
                    sudo dpkg -i /tmp/synergy.deb 2>/dev/null || true
                    sudo apt-get install -f -y || die "Failed to fix Synergy dependencies."
                    rm -f /tmp/synergy.deb
                    ;;
                fedora)
                    log_info "Downloading Synergy (.rpm)..."
                    wget --progress=bar:force "URL_DO_SYNERGY_RPM" -O /tmp/synergy.rpm \
                        || die "Failed to download Synergy."
                    sudo dnf install -y /tmp/synergy.rpm || die "Failed to install Synergy."
                    rm -f /tmp/synergy.rpm
                    ;;
                *)
                    die "Unsupported distro for Synergy: $DISTRO"
                    ;;
            esac
            ;;
        *)
            die "No native install handler defined for: $app"
            ;;
    esac
}

_category_menu() {
    local header="$1"
    shift
    local -a apps=("$@")

    local selections
    selections=$(printf '%s\n' "${apps[@]}" \
        | _fzf_menu -m \
              --prompt="$header > " \
              --header="[TAB] Select  [ENTER] Install  [ESC] Back" \
              --height=18 \
              --layout=reverse \
              --border=rounded \
              --pointer="▶" \
              --color="bg:#121212,bg+:#1e1e1e,fg:#d1d1d1,fg+:#ffffff,hl:#89b4fa,prompt:#cba6f7,pointer:#f38ba8,marker:#a6e3a1,header:#f9e2af,border:#2a2a2a" \
              --no-info)

    [[ -z "$selections" ]] && { log_warn "No app selected."; return 0; }

    while read -r app; do
        [[ -z "$app" ]] && continue
        _install_app "$app"
    done <<< "$selections"
}

_get_apps_for_category() {
    local category="$1"
    local app
    for app in "${!APP_CATEGORY[@]}"; do
        if [[ "${APP_CATEGORY[$app]}" == "$category" ]]; then
            printf '%s\n' "$app"
        fi
    done | sort
}

menu_browsers() {
    local -a apps=()
    mapfile -t apps < <(_get_apps_for_category "Browsers")
    _category_menu "Browsers" "${apps[@]}"
}

menu_media() {
    local -a apps=()
    mapfile -t apps < <(_get_apps_for_category "Media")
    _category_menu "Media" "${apps[@]}"
}

menu_communication() {
    local -a apps=()
    mapfile -t apps < <(_get_apps_for_category "Communication")
    _category_menu "Communication" "${apps[@]}"
}

menu_productivity() {
    local -a apps=()
    mapfile -t apps < <(_get_apps_for_category "Productivity")
    _category_menu "Productivity" "${apps[@]}"
}

menu_gaming() {
    local -a apps=()
    mapfile -t apps < <(_get_apps_for_category "Gaming")
    _category_menu "Gaming" "${apps[@]}"
}

menu_system_tools() {
    local -a apps=()
    mapfile -t apps < <(_get_apps_for_category "System Tools")
    _category_menu "System Tools" "${apps[@]}"
}

menu_terminals() {
    local -a apps=()
    mapfile -t apps < <(_get_apps_for_category "Terminals")
    _category_menu "Terminals" "${apps[@]}"
}

setup_apps() {
    while true; do
        local choice
        choice=$(printf '%s\n' \
            "  Browsers" \
            "  Media" \
            "  Communication" \
            "  Productivity" \
            "  Gaming" \
            "  System Tools" \
            "  Terminals" \
            "  Development" \
            "  Exit" \
            | _fzf_menu \
              --prompt="Apps > " \
              --header="INSTALL APPS  │  [ENTER] select   [ESC] back" \
              --height=15 \
              --layout=reverse \
              --border=rounded \
              --pointer="▶" \
              --color="bg:#121212,bg+:#1e1e1e,fg:#d1d1d1,fg+:#ffffff,hl:#89b4fa,prompt:#cba6f7,pointer:#f38ba8,header:#f9e2af,border:#2a2a2a" \
              --no-info)

        case "$choice" in
            *Browsers)       menu_browsers ;;
            *Media)          menu_media ;;
            *Communication)  menu_communication ;;
            *Productivity)   menu_productivity ;;
            *Gaming)         menu_gaming ;;
            *"System Tools") menu_system_tools ;;
            *Terminals)      menu_terminals ;;
            *Development)
                source "$BASE_DIR/modules/development_setup.sh"
                setup_development
                ;;
            *Exit|"") return 0 ;;
        esac
    done
}