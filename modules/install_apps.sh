#!/usr/bin/env bash
set -uo pipefail

declare -A APP_REGISTRY

APP_REGISTRY["Firefox"]="pkg|firefox|org.mozilla.firefox|-"
APP_REGISTRY["Chromium"]="pkg|chromium|org.chromium.Chromium|-"
APP_REGISTRY["Brave"]="flatpak|-|com.brave.Browser|-"
APP_REGISTRY["Zen Browser"]="flatpak|-|app.zen_browser.zen|-"
APP_REGISTRY["Google Chrome"]="native|-|-|-"
APP_REGISTRY["Helium Browser"]="native|-|-|-"
APP_REGISTRY["Opera"]="native|-|-|-"

APP_REGISTRY["VLC"]="pkg|vlc|org.videolan.VLC|-"
APP_REGISTRY["Spotify"]="flatpak|-|com.spotify.Client|-"
APP_REGISTRY["Celluloid"]="pkg|celluloid|io.github.celluloid_player.Celluloid|-"
APP_REGISTRY["Rhythmbox"]="pkg|rhythmbox|org.gnome.Rhythmbox3|-"
APP_REGISTRY["OBS Studio"]="pkg|obs-studio|com.obsproject.Studio|-"
APP_REGISTRY["MPV"]="pkg|mpv|-|-"
APP_REGISTRY["Handbrake"]="pkg|handbrake|fr.handbrake.ghb|-"
APP_REGISTRY["Kdenlive"]="pkg|kdenlive|org.kde.kdenlive|-"
APP_REGISTRY["Synergy"]="native|-|-|-"

APP_REGISTRY["Discord"]="flatpak|-|com.discordapp.Discord|-"
APP_REGISTRY["Telegram"]="flatpak|-|org.telegram.desktop|-"
APP_REGISTRY["Signal"]="flatpak|-|org.signal.Signal|-"
APP_REGISTRY["Slack"]="flatpak|-|com.slack.Slack|-"
APP_REGISTRY["Zoom"]="flatpak|-|us.zoom.Zoom|-"
APP_REGISTRY["Teams"]="flatpak|-|com.microsoft.Teams|-"
APP_REGISTRY["YouTube Music Desktop"]="native|-|-|-"

APP_REGISTRY["LibreOffice"]="pkg|libreoffice|org.libreoffice.LibreOffice|-"
APP_REGISTRY["Obsidian"]="flatpak|-|md.obsidian.Obsidian|-"
APP_REGISTRY["Thunderbird"]="pkg|thunderbird|org.mozilla.Thunderbird|-"
APP_REGISTRY["Bitwarden"]="flatpak|-|com.bitwarden.desktop|-"
APP_REGISTRY["SyncThingy"]="flatpak|-|com.github.zocker_160.SyncThingy|-"
APP_REGISTRY["Syncthing Tray"]="flatpak|-|io.github.martchus.syncthingtray|-"
APP_REGISTRY["Flameshot"]="pkg|flameshot|org.flameshot.Flameshot|-"
APP_REGISTRY["GIMP"]="pkg|gimp|org.gimp.GIMP|-"
APP_REGISTRY["Inkscape"]="pkg|inkscape|org.inkscape.Inkscape|-"

APP_REGISTRY["Steam"]="pkg|steam|com.valvesoftware.Steam|-"
APP_REGISTRY["Lutris"]="pkg|lutris|net.lutris.Lutris|-"
APP_REGISTRY["Heroic Games Launcher"]="flatpak|-|com.heroicgameslauncher.hgl|-"
APP_REGISTRY["ProtonUp-Qt"]="flatpak|-|net.davidotek.pupgui2|-"
APP_REGISTRY["MangoHud"]="pkg|mangohud|-|-"
APP_REGISTRY["Sober"]="flatpak|-|org.vinegarhq.Sober|-"
APP_REGISTRY["Bottles"]="flatpak|-|com.usebottles.bottles|-"

APP_REGISTRY["Alacritty"]="pkg|alacritty|-|-"
APP_REGISTRY["Kitty"]="pkg|kitty|-|-"
APP_REGISTRY["Konsole"]="pkg|konsole|-|-"
APP_REGISTRY["Ghostty"]="terminal|ghostty|-|-"

APP_REGISTRY["htop"]="pkg|htop|-|-"
APP_REGISTRY["btop"]="pkg|btop|-|-"
APP_REGISTRY["ncdu"]="pkg|ncdu|-|-"
APP_REGISTRY["tree"]="pkg|tree|-|-"
APP_REGISTRY["tmux"]="pkg|tmux|-|-"
APP_REGISTRY["jq"]="pkg|jq|-|-"
APP_REGISTRY["bat"]="pkg|bat|-|-"
APP_REGISTRY["ripgrep"]="pkg|ripgrep|-|-"
APP_REGISTRY["fd"]="native|-|-|-"
APP_REGISTRY["neofetch"]="pkg|neofetch|-|-"
APP_REGISTRY["fastfetch"]="pkg|fastfetch|-|-"
APP_REGISTRY["net-tools"]="pkg|net-tools|-|-"
APP_REGISTRY["openssh"]="native|-|-|-"

_fzf_menu() {
    local tmp_in tmp_out
    tmp_in=$(mktemp)
    tmp_out=$(mktemp)
    cat > "$tmp_in"
    fzf "$@" < "$tmp_in" > "$tmp_out" || true
    cat "$tmp_out"
    rm -f "$tmp_in" "$tmp_out"
}

_is_installed() {
    local app="$1"
    local entry="${APP_REGISTRY[$app]:-}"
    local method pkg_name flatpak_id aur_pkg
    IFS='|' read -r method pkg_name flatpak_id aur_pkg <<< "$entry"

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
}

_remove_app() {
    local app="$1"
    local entry="${APP_REGISTRY[$app]:-}"
    local method pkg_name flatpak_id aur_pkg
    IFS='|' read -r method pkg_name flatpak_id aur_pkg <<< "$entry"

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

    local method pkg_name flatpak_id aur_pkg
    IFS='|' read -r method pkg_name flatpak_id aur_pkg <<< "$entry"

    log_info "Installing $app..."

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
                    wget --progress=bar:force "https://github.com/ytmdesktop/ytmdesktop/releases/download/v2.0.11/youtube-music-desktop-app_2.0.11_amd64.deb" \
                        -O /tmp/ytmdesktop.deb \
                        || die "Failed to download YouTube Music Desktop."
                    sudo dpkg -i /tmp/ytmdesktop.deb 2>/dev/null || true
                    sudo apt-get install -f -y || die "Failed to fix YouTube Music Desktop dependencies."
                    rm -f /tmp/ytmdesktop.deb
                    ;;
                fedora)
                    log_info "YouTube Music Desktop is available via AUR for Fedora containers or install from releases."
                    die "YouTube Music Desktop installation not yet supported on Fedora. Please use the AppImage from GitHub releases."
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

menu_browsers() {
    _category_menu "Browsers" \
        "Firefox" "Chromium" "Brave" "Zen Browser" "Google Chrome" "Helium Browser"
}

menu_media() {
    _category_menu "Media" \
        "VLC" "MPV" "Spotify" "Celluloid" "Rhythmbox" \
        "OBS Studio" "Handbrake" "Kdenlive" "YouTube Music Desktop"
}

menu_communication() {
    _category_menu "Communication" \
        "Discord" "Telegram" "Signal" "Slack" "Zoom" "Teams"
}

menu_productivity() {
    _category_menu "Productivity" \
        "LibreOffice" "Obsidian" "Thunderbird" "Bitwarden" \
        "Flameshot" "GIMP" "Inkscape" \
        "SyncThingy" "Syncthing Tray" "Synergy"
}

menu_gaming() {
    _category_menu "Gaming" \
        "Steam" "Lutris" "Heroic Games Launcher" \
        "ProtonUp-Qt" "MangoHud" "Sober" "Bottles"
}

menu_system_tools() {
    _category_menu "System Tools" \
        "htop" "btop" "ncdu" "tree" \
        "tmux" "jq" "bat" "ripgrep" "fd" \
        "neofetch" "fastfetch" \
        "net-tools" "openssh" "Synergy"
}

menu_terminals() {
    _category_menu "Terminals" \
        "Alacritty" "Kitty" "Konsole" "Ghostty"
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