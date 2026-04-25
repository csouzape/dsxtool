#!/usr/bin/env bash
set -uo pipefail

declare -A APP_REGISTRY

APP_REGISTRY["Firefox"]="pkg|firefox|org.mozilla.firefox|-"
APP_REGISTRY["Chromium"]="pkg|chromium|org.chromium.Chromium|-"
APP_REGISTRY["Brave"]="flatpak|-|com.brave.Browser|-"
APP_REGISTRY["Zen Browser"]="flatpak|-|app.zen_browser.zen|-"
APP_REGISTRY["Google Chrome"]="native|-|-|-"

APP_REGISTRY["VLC"]="pkg|vlc|org.videolan.VLC|-"
APP_REGISTRY["Spotify"]="flatpak|-|com.spotify.Client|-"
APP_REGISTRY["Celluloid"]="pkg|celluloid|io.github.celluloid_player.Celluloid|-"
APP_REGISTRY["Rhythmbox"]="pkg|rhythmbox|org.gnome.Rhythmbox3|-"
APP_REGISTRY["OBS Studio"]="pkg|obs-studio|com.obsproject.Studio|-"
APP_REGISTRY["MPV"]="pkg|mpv|-|-"
APP_REGISTRY["Handbrake"]="pkg|handbrake|fr.handbrake.ghb|-"
APP_REGISTRY["Kdenlive"]="pkg|kdenlive|org.kde.kdenlive|-"

APP_REGISTRY["Discord"]="flatpak|-|com.discordapp.Discord|-"
APP_REGISTRY["Telegram"]="flatpak|-|org.telegram.desktop|-"
APP_REGISTRY["Signal"]="flatpak|-|org.signal.Signal|-"
APP_REGISTRY["Slack"]="flatpak|-|com.slack.Slack|-"
APP_REGISTRY["Zoom"]="flatpak|-|us.zoom.Zoom|-"
APP_REGISTRY["Teams"]="flatpak|-|com.microsoft.Teams|-"

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
        native)
            case "$app" in
                "Google Chrome") command -v google-chrome-stable &>/dev/null || command -v google-chrome &>/dev/null ;;
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
        native)
            case "$app" in
                "Google Chrome")
                    case "$DISTRO" in
                        arch)   sudo pacman -Rns --noconfirm google-chrome ;;
                        debian) sudo apt-get remove -y google-chrome-stable ;;
                        fedora) sudo dnf remove -y google-chrome-stable ;;
                    esac
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
            if ! command -v yay &>/dev/null; then
                die "yay is not installed. Please run 'Setup yay' first."
            fi
            sudo -u "${SUDO_USER:-$USER}" yay -S --noconfirm "$aur_pkg" \
                || die "Failed to install $app via AUR."
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

_install_native_app() {
    local app="$1"
    case "$app" in
        "Google Chrome")
            case "$DISTRO" in
                arch)
                    if ! command -v yay &>/dev/null; then
                        die "yay is not installed. Please run 'Setup yay' first."
                    fi
                    sudo -u "${SUDO_USER:-$USER}" yay -S --noconfirm google-chrome \
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
        "Firefox" "Chromium" "Brave" "Zen Browser" "Google Chrome"
}

menu_media() {
    _category_menu "Media" \
        "VLC" "MPV" "Spotify" "Celluloid" "Rhythmbox" \
        "OBS Studio" "Handbrake" "Kdenlive"
}

menu_communication() {
    _category_menu "Communication" \
        "Discord" "Telegram" "Signal" "Slack" "Zoom" "Teams"
}

menu_productivity() {
    _category_menu "Productivity" \
        "LibreOffice" "Obsidian" "Thunderbird" "Bitwarden" \
        "Flameshot" "GIMP" "Inkscape" \
        "SyncThingy" "Syncthing Tray"
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
        "net-tools" "openssh"
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
            "  Development" \
            "  Exit" \
            | _fzf_menu \
              --prompt="Apps > " \
              --header="INSTALL APPS  │  [ENTER] select   [ESC] back" \
              --height=14 \
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
            *Development)
                source "$BASE_DIR/modules/development_setup.sh"
                setup_development
                ;;
            *Exit|"") return 0 ;;
        esac
    done
}