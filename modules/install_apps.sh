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
    "Brave" "native|-|-|-;flatpak|-|com.brave.Browser|-;aur|-|-|brave-bin" \
    "Zen Browser" "native|-|-|-;flatpak|-|app.zen_browser.zen|-;aur|-|-|zen-browser-bin" \
    "Google Chrome" "native|-|-|-;flatpak|-|com.google.Chrome|-;aur|-|-|google-chrome-bin" \
    "Helium Browser" "native|-|-|-" \
    "Opera" "native|deb|-|-;native|rpm|-|-;native|snap|-|-|;flatpak|-|com.opera.Opera|-|;aur|-|-|opera-bin" \
    "OperaGx" "native|deb|-|-;native|rpm|-|-;native|snap|-|-|;flatpak|-|com.opera.opera-gx|-|;aur|-|-|opera-gx-bin" \
    "LibreWolf" "native|deb|-|-;native|rpm|-|-;flatpak|-|io.gitlab.librewolf-community|-;aur|-|-|librewolf-bin" \

register_category_apps "Media" \
    "VLC" "pkg|vlc|-|-;flatpak|-|org.videolan.VLC|-" \
    "Spotify" "pkg|spotify|-|-;native|deb|-|-;native|rpm|-|-;native|snap|-|-;flatpak|-|com.spotify.Client|-;aur|-|-|spotify" \
    "Celluloid" "pkg|celluloid|-|-;flatpak|-|io.github.celluloid_player.Celluloid|-|-;native|snap|-|-|;aur|-|-|celluloid" \
    "Rhythmbox" "pkg|rhythmbox|org.gnome.Rhythmbox3|-" \
    "OBS Studio" "pkg|obs-studio|-|-;native|deb|-|-;native|rpm|-|-;native|snap|-|-;flatpak|-|org.obsproject.OBS|-;aur|-|-|obs-studio-bin" \
    "MPV" "pkg|mpv|-|-" \
    "Handbrake" "pkg|handbrake|fr.handbrake.ghb|-" \
    "kdenlive" "pkg|kdenlive|-|-;native|deb|-|-;native|rpm|-|-;native|snap|-|-;flatpak|-|org.kde.kdenlive|-;aur|-|-|kdenlive" \
    "Synergy" "native|-|-|-" \
    "EasyEffects" "pkg|easyeffects|-|-;flatpak|-|com.github.wwmm.easyeffects|-;aur|-|-|easyeffects" \
    "YouTube Music Desktop" "native|-|-|-"

register_category_apps "Communication" \
    "Discord" "pkg|discord|-|-;native|deb|-|-;native|rpm|-|-;native|snap|-|-;flatpak|-|com.discordapp.Discord|-;aur|-|-|discord-latest-bin" \
    "Telegram" "pkg|telegram-desktop|-|-;native|deb|-|-;native|rpm|-|-;native|snap|-|-;native|tarball|-|-;flatpak|-|org.telegram.desktop|-;aur|-|-|telegram-desktop-bin" \
    "Signal" "flatpak|-|org.signal.Signal|-" \
   "Slack" "native|deb|-|-;native|rpm|-|-;native|snap|-|-;flatpak|-|com.slack.Slack|-;aur|-|-|slack-desktop" \
    "Zoom" "native|deb|-|-;native|rpm|-|-;native|snap|-|-;flatpak|-|us.zoom.Zoom|-;aur|-|-|zoom" \
    "Teams" "native|deb|-|-;native|rpm|-|-;native|snap|-|-|;flatpak|-|com.github.IsmaelMartinez.teams_for_linux|-;aur|-|-|teams-for-linux-bin"

register_category_apps "Productivity" \
    "LibreOffice" "native|arch-fresh|-|-;native|arch-still|-|-;native|deb|-|-;native|rpm|-|-;native|snap|-|-;flatpak|-|org.libreoffice.LibreOffice|-" \
    "Obsidian" "flatpak|-|md.obsidian.Obsidian|-" \
    "Thunderbird" "pkg|thunderbird|-|-;native|snap|-|-;flatpak|-|org.mozilla.Thunderbird|-" \
    "Bitwarden" "flatpak|-|com.bitwarden.desktop|-" \
    "SyncThingy" "flatpak|-|com.github.zocker_160.SyncThingy|-" \
    "Syncthing Tray" "flatpak|-|io.github.martchus.syncthingtray|-" \
    "Flameshot" "pkg|flameshot|org.flameshot.Flameshot|-" \
    "GIMP" "pkg|gimp|-|-;native|snap|-|-;flatpak|-|org.gimp.GIMP|-;aur|-|-|gimp-git" \
    "Inkscape" "pkg|inkscape|-|-;native|snap|-|-;flatpak|-|org.inkscape.Inkscape|-;aur|-|-|inkscape-bin" \

register_category_apps "Gaming" \
    "Steam" "pkg|steam|com.valvesoftware.Steam|-" \
    "Lutris" "pkg|lutris|net.lutris.Lutris|-" \
    "Heroic Games Launcher" "flatpak|-|com.heroicgameslauncher.hgl|-" \
    "ProtonUp-Qt" "flatpak|-|net.davidotek.pupgui2|-" \
    "MangoHud" "pkg|mangohud|-|-" \
    "Sober" "flatpak|-|org.vinegarhq.Sober|-" \
    "Bottles" "flatpak|-|com.usebottles.bottles|-"

register_category_apps "System Tools" \
    "htop" "pkg|htop|-|-" \
    "btop" "pkg|btop|-|-" \
    "OpenRGB" "native|deb|-|-;native|rpm|-|-;flatpak|-|org.openrgb.OpenRGB|-" \
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

register_category_apps "Terminals" \
    "Alacritty" "pkg|alacritty|-|-" \
    "Kitty" "pkg|kitty|-|-" \
    "Konsole" "pkg|konsole|-|-" \
    "Ghostty" "terminal|ghostty|-|-"

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
    local app="$1"
    local target="$2"
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
        flatpak)
            case "$app" in
                "Google Chrome") printf 'Flatpak (Google Chrome)' ;;
                "Brave") printf 'Flatpak (Brave)' ;;
                "Zen Browser") printf 'Flatpak (Zen Browser)' ;;
                *) printf 'Flatpak (%s)' "${flatpak_id:-$pkg_name}" ;;
            esac
            ;;
        aur)
            case "$app" in
                "Google Chrome") printf 'AUR (Google Chrome)' ;;
                "Brave") printf 'AUR (Brave)' ;;
                *) printf 'AUR (%s)' "${aur_pkg:-$pkg_name}" ;;
            esac
            ;;
        terminal) printf 'Terminal (%s)' "$pkg_name" ;;
        native)
            case "$app" in
                "Google Chrome") printf 'Official (Google Chrome)' ;;
                "Brave") printf 'Official (Brave)' ;;
                "Zen Browser") printf 'Official (Zen Browser)' ;;
                "Opera")
                    case "$pkg_name" in
                        deb) printf 'Official (.deb)' ;;
                        rpm) printf 'Official (.rpm)' ;;
                        snap) printf 'Snap' ;;
                        *) printf 'Official (Opera)' ;;
                    esac
                    ;;
                "OperaGx")
                    case "$pkg_name" in
                        deb) printf 'Official (.deb)' ;;
                        rpm) printf 'Official (.rpm)' ;;
                        snap) printf 'Snap' ;;
                        *) printf 'Official (Opera)' ;;
                    esac
                    ;;
                "LibreWolf")
                    case "$pkg_name" in
                        deb) printf 'Official (.deb, extrepo)' ;;
                        rpm) printf 'Official (.rpm, repo)' ;;
                        *)   printf 'Official (LibreWolf)' ;;
                    esac
                    ;;
                "Teams")
                    case "$pkg_name" in
                        deb) printf 'Official (.deb)' ;;
                        rpm) printf 'Official (.rpm)' ;;
                        snap) printf 'Snap' ;;
                        *) printf 'Official (Teams)' ;;
                    esac
                    ;;
                "Slack")
                    case "$pkg_name" in
                        deb) printf 'Official (.deb)' ;;
                        rpm) printf 'Official (.rpm)' ;;
                        snap) printf 'Snap' ;;
                        *) printf 'Official (Slack)' ;;
                    esac
                    ;;
                "Telegram")
                    case "$pkg_name" in
                        deb)     printf 'Official (.deb)' ;;
                        rpm)     printf 'Official (.rpm, RPM Fusion)' ;;
                        snap)    printf 'Snap' ;;
                        tarball) printf 'Official (tarball, static)' ;;
                        *)       printf 'Official (Telegram)' ;;
                    esac
                    ;;
                "Zoom")
                    case "$pkg_name" in
                        deb) printf 'Official (.deb)' ;;
                        rpm) printf 'Official (.rpm)' ;;
                        snap) printf 'Snap' ;;
                        *) printf 'Official (Zoom)' ;;
                    esac
                    ;;
                "Inkscape")
                    case "$pkg_name" in
                        snap) printf 'Snap' ;;
                        *) printf 'Official (Inkscape)' ;;
                    esac
                    ;;
                "LibreOffice")
                    case "$pkg_name" in
                        arch-fresh) printf 'Official (Fresh, pacman)' ;;
                        arch-still) printf 'Official (Still, pacman)' ;;
                        deb)        printf 'Official (.deb)' ;;
                        rpm)        printf 'Official (.rpm)' ;;
                        snap)       printf 'Snap' ;;
                        *)          printf 'Official (LibreOffice)' ;;
                    esac
                    ;;
                "GIMP")
                    case "$pkg_name" in
                        snap) printf 'Snap' ;;
                        *) printf 'Official (GIMP)' ;;
                    esac
                    ;;
                "OpenRGB")
                    case "$pkg_name" in
                        deb) printf 'Official (.deb)' ;;
                        rpm) printf 'Official (.rpm)' ;;
                        *) printf 'Official (OpenRGB)' ;;
                    esac
                    ;;
                *) printf 'Native (%s)' "$pkg_name" ;;
            esac
            ;;
        *) printf 'Unknown (%s)' "$target" ;;
    esac
}

_can_use_aur() {
    [[ "$DISTRO" == "arch" ]] && get_aur_helper >/dev/null 2>&1
}

_can_use_snap() {
    command -v snap >/dev/null 2>&1 && snap version >/dev/null 2>&1
}

_get_available_targets() {
    local app="$1"
    local entry="$2"
    local -a targets=()
    local target method pkg_name flatpak_id aur_pkg

    IFS=';' read -r -a targets <<< "$entry"

    for target in "${targets[@]}"; do
        [[ -z "${target//[[:space:]]/}" ]] && continue
        IFS='|' read -r method pkg_name flatpak_id aur_pkg <<< "$target"

        case "$method" in
            flatpak|terminal)
                 printf '%s\n' "$target"
                 ;;
            pkg)
                if [[ "$app" == "OBS Studio" || "$app" == "Spotify" || "$app" == "Zen Browser" || "$app" == "kdenlive" || "$app" == "Discord" || "$app" == "Thunderbird" || "$app" == "Telegram" || "$app" == "LibreOffice" ]]; then
                    [[ "$DISTRO" == "arch" ]] && printf '%s\n' "$target"
                else
                    printf '%s\n' "$target"
                fi
                ;;
            native)
                case "$pkg_name" in
                    deb)  [[ "$DISTRO" == "debian" ]] && printf '%s\n' "$target" ;;
                    rpm)  [[ "$DISTRO" == "fedora" ]] && printf '%s\n' "$target" ;;
                    snap) _can_use_snap && printf '%s\n' "$target" ;;
                    *)    printf '%s\n' "$target" ;;
                esac
                ;;

            aur)
                if _can_use_aur; then
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

    mapfile -t options < <(_get_available_targets "$app" "$entry")

    if [[ ${#options[@]} -eq 0 ]]; then
        return 1
    fi

    if [[ ${#options[@]} -eq 1 ]]; then
        printf '%s\n' "${options[0]}"
        return 0
    fi

    for target in "${options[@]}"; do
        labels+=("$(_target_label "$app" "$target")")
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
                    "Zen Browser") command -v zen-browser &>/dev/null || command -v zen &>/dev/null || command -v zen-browser-bin &>/dev/null || [[ -x "$HOME/.local/bin/zen" ]] || [[ -x "$HOME/.local/bin/zen-browser" ]] ;;
                    "Helium Browser") [[ -x /opt/helium/helium ]] || command -v helium &>/dev/null || command -v helium-browser &>/dev/null || command -v helium-browser-bin &>/dev/null ;;
                    "Opera")
                        case "$pkg_name" in
                            deb) dpkg -s opera-stable &>/dev/null || dpkg -s opera-developer &>/dev/null ;;
                            rpm) rpm -q opera-stable &>/dev/null || rpm -q opera-developer &>/dev/null ;;
                            snap) snap list opera &>/dev/null ;;
                            *) return 1 ;;
                        esac
                        ;;
                    "OperaGx")
                        case "$pkg_name" in
                            deb) dpkg -s opera-gx-stable &>/dev/null || dpkg -s opera-gx-developer &>/dev/null ;;
                            rpm) rpm -q opera-gx-stable &>/dev/null || rpm -q opera-gx-developer &>/dev/null ;;
                            snap) snap list opera-gx &>/dev/null ;;
                            *) return 1 ;;
                        esac
                        ;;
                    "LibreWolf")
                        case "$pkg_name" in
                            deb) dpkg -s librewolf &>/dev/null ;;
                            rpm) rpm -q librewolf &>/dev/null ;;
                            *)   return 1 ;;
                        esac
                        ;;
                    "OBS Studio")
                        case "$pkg_name" in
                            deb) dpkg -s obs-studio &>/dev/null || dpkg -s obs-studio-bin &>/dev/null ;;
                            rpm) rpm -q obs-studio &>/dev/null || rpm -q obs-studio-bin &>/dev/null ;;
                            snap) snap list obs-studio &>/dev/null ;;
                            *) return 1 ;;
                        esac
                        ;;
                    "Spotify")
                        case "$pkg_name" in
                            deb) dpkg -s spotify-client &>/dev/null ;;
                            rpm) rpm -q spotify-client &>/dev/null ;;
                            snap) snap list spotify &>/dev/null ;;
                            *) return 1 ;;
                        esac
                        ;;
                    "kdenlive")
                        case "$pkg_name" in
                            deb)  dpkg -s kdenlive &>/dev/null ;;
                            rpm)  rpm -q kdenlive &>/dev/null ;;
                            snap) snap list kdenlive &>/dev/null ;;
                            *)    return 1 ;;
                        esac
                        ;;
                    "Discord")
                        case "$pkg_name" in
                            deb)  dpkg -s discord &>/dev/null ;;
                            rpm)  rpm -q discord &>/dev/null ;;
                            snap) snap list discord &>/dev/null ;;
                            *)    return 1 ;;
                        esac
                        ;;
                    "Teams")
                        case "$pkg_name" in
                            deb)  dpkg -s teams-for-linux &>/dev/null ;;
                            rpm)  rpm -q teams-for-linux &>/dev/null ;;
                            snap) snap list teams-for-linux &>/dev/null ;;
                            *)    return 1 ;;
                        esac
                        ;;
                    "Slack")
                        case "$pkg_name" in
                            deb)  dpkg -s slack-desktop &>/dev/null ;;
                            rpm)  rpm -q slack &>/dev/null ;;
                            snap) snap list slack &>/dev/null ;;
                            *)    return 1 ;;
                        esac
                        ;;
                    "Telegram")
                        case "$pkg_name" in
                            deb)     dpkg -s telegram-desktop &>/dev/null ;;
                            rpm)     rpm -q telegram-desktop &>/dev/null ;;
                            snap)    snap list telegram-desktop &>/dev/null ;;
                            tarball) [[ -x /opt/telegram-desktop/Telegram ]] || command -v telegram &>/dev/null ;;
                            *)       return 1 ;;
                        esac
                        ;;
                    "Zoom")
                        case "$pkg_name" in
                            deb)  dpkg -s zoom &>/dev/null ;;
                            rpm)  rpm -q zoom &>/dev/null ;;
                            snap) snap list zoom-client &>/dev/null ;;
                            *)    return 1 ;;
                        esac
                        ;;
                    "Inkscape")
                        case "$pkg_name" in
                            snap) snap list inkscape &>/dev/null ;;
                            *)    return 1 ;;
                        esac
                        ;;
                    "LibreOffice")
                        case "$pkg_name" in
                            arch-fresh) pacman -Q libreoffice-fresh &>/dev/null ;;
                            arch-still) pacman -Q libreoffice-still &>/dev/null ;;
                            deb)        dpkg -s libreoffice &>/dev/null ;;
                            rpm)        rpm -q libreoffice &>/dev/null ;;
                            snap)       snap list libreoffice &>/dev/null ;;
                            *)          return 1 ;;
                        esac
                        ;;
                    "GIMP")
                        case "$pkg_name" in
                            snap) snap list gimp &>/dev/null ;;
                            *)    return 1 ;;
                        esac
                        ;;
                    "OpenRGB")
                        case "$pkg_name" in
                            deb) dpkg -s openrgb &>/dev/null ;;
                            rpm) rpm -q openrgb &>/dev/null ;;
                            *)   return 1 ;;
                        esac
                        ;;
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
    local selected_target=""   # nunca confiar no cache aqui — sempre redetectar o que está de fato instalado
    local -a targets=()
    local target method pkg_name flatpak_id aur_pkg

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
                    "Brave") command -v brave-browser &>/dev/null || command -v brave &>/dev/null ;;
                    "Zen Browser") command -v zen-browser &>/dev/null || command -v zen &>/dev/null || command -v zen-browser-bin &>/dev/null || [[ -x "$HOME/.local/bin/zen" ]] || [[ -x "$HOME/.local/bin/zen-browser" ]] ;;
                    "Helium Browser") [[ -x /opt/helium/helium ]] || command -v helium &>/dev/null || command -v helium-browser &>/dev/null || command -v helium-browser-bin &>/dev/null ;;
                    "Opera")
                        case "$pkg_name" in
                            deb) dpkg -s opera-stable &>/dev/null || dpkg -s opera-developer &>/dev/null ;;
                            rpm) rpm -q opera-stable &>/dev/null || rpm -q opera-developer &>/dev/null ;;
                            snap) snap list opera &>/dev/null ;;
                            *) false ;;
                        esac
                        ;;
                    "OperaGx")
                        case "$pkg_name" in
                            deb) dpkg -s opera-gx-stable &>/dev/null || dpkg -s opera-gx-developer &>/dev/null ;;
                            rpm) rpm -q opera-gx-stable &>/dev/null || rpm -q opera-gx-developer &>/dev/null ;;
                            snap) snap list opera-gx &>/dev/null ;;
                            *) false ;;
                        esac
                        ;;
                    "LibreWolf")
                        case "$pkg_name" in
                            deb) dpkg -s librewolf &>/dev/null ;;
                            rpm) rpm -q librewolf &>/dev/null ;;
                            *)   false ;;
                        esac
                        ;;
                    "OBS Studio")
                        case "$pkg_name" in
                            deb) dpkg -s obs-studio &>/dev/null || dpkg -s obs-studio-bin &>/dev/null ;;
                            rpm) rpm -q obs-studio &>/dev/null || rpm -q obs-studio-bin &>/dev/null ;;
                            snap) snap list obs-studio &>/dev/null ;;
                            *) false ;;
                        esac
                        ;;
                    "Spotify")
                        case "$pkg_name" in
                            deb) dpkg -s spotify-client &>/dev/null ;;
                            rpm) rpm -q spotify-client &>/dev/null ;;
                            snap) snap list spotify &>/dev/null ;;
                            *) false ;;
                        esac
                        ;;
                    "kdenlive")
                        case "$pkg_name" in
                            deb)  dpkg -s kdenlive &>/dev/null ;;
                            rpm)  rpm -q kdenlive &>/dev/null ;;
                            snap) snap list kdenlive &>/dev/null ;;
                            *)    false ;;
                        esac
                        ;;
                    "Discord")
                        case "$pkg_name" in
                            deb)  dpkg -s discord &>/dev/null ;;
                            rpm)  rpm -q discord &>/dev/null ;;
                            snap) snap list discord &>/dev/null ;;
                            *)    false ;;
                        esac
                        ;;
                    "Teams")
                        case "$pkg_name" in
                            deb) dpkg -s teams-for-linux &>/dev/null ;;
                            rpm) rpm -q teams-for-linux &>/dev/null ;;
                            snap) snap list teams-for-linux &>/dev/null ;;
                            *)    false ;;
                        esac
                        ;;
                    "Slack")
                        case "$pkg_name" in
                            deb)  dpkg -s slack-desktop &>/dev/null ;;
                            rpm)  rpm -q slack &>/dev/null ;;
                            snap) snap list slack &>/dev/null ;;
                            *)    false ;;
                        esac
                        ;;
                    "Telegram")
                        case "$pkg_name" in
                            deb)     dpkg -s telegram-desktop &>/dev/null ;;
                            rpm)     rpm -q telegram-desktop &>/dev/null ;;
                            snap)    snap list telegram-desktop &>/dev/null ;;
                            tarball) [[ -x /opt/telegram-desktop/Telegram ]] || command -v telegram &>/dev/null ;;
                            *)       false ;;
                        esac
                        ;;
                    "Zoom")
                        case "$pkg_name" in
                            deb)  dpkg -s zoom &>/dev/null ;;
                            rpm)  rpm -q zoom &>/dev/null ;;
                            snap) snap list zoom-client &>/dev/null ;;
                            *)    false ;;
                        esac
                        ;;
                    "Inkscape")
                        case "$pkg_name" in
                            snap) snap list inkscape &>/dev/null ;;
                            *)    false ;;
                        esac
                        ;;
                    "LibreOffice")
                        case "$pkg_name" in
                            arch-fresh) pacman -Q libreoffice-fresh &>/dev/null ;;
                            arch-still) pacman -Q libreoffice-still &>/dev/null ;;
                            deb)        dpkg -s libreoffice &>/dev/null ;;
                            rpm)        rpm -q libreoffice &>/dev/null ;;
                            snap)       snap list libreoffice &>/dev/null ;;
                            *)          false ;;
                        esac
                        ;;
                    "GIMP")
                        case "$pkg_name" in
                            snap) snap list gimp &>/dev/null ;;
                            *)    false ;;
                        esac
                        ;;
                    "OpenRGB")
                        case "$pkg_name" in
                            deb)     dpkg -s openrgb &>/dev/null ;;
                            rpm)     rpm -q openrgb &>/dev/null ;;
                            flatpak) flatpak list --app 2>/dev/null | grep -q org.openrgb.OpenRGB ;;
                            *)       false ;;
                        esac
                        ;;
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

    if [[ -z "$selected_target" ]]; then
        log_warn "$app doesn't seem to be installed. Nothing to remove."
        return 0
    fi

    IFS='|' read -r method pkg_name flatpak_id aur_pkg <<< "$selected_target"

    log_info "Removing $app..."

    local remove_status=0
    case "$method" in
        pkg)
            case "$DISTRO" in
                arch)   sudo pacman -Rns --noconfirm "$pkg_name" ;;
                debian) sudo apt-get remove -y "$pkg_name" ;;
                fedora) sudo dnf remove -y "$pkg_name" ;;
            esac
            remove_status=$?
            ;;
        flatpak)
            flatpak uninstall -y "$flatpak_id"
            remove_status=$?
            ;;
        aur)
            sudo pacman -Rns --noconfirm "$aur_pkg"
            remove_status=$?
            ;;
        terminal)
            case "$DISTRO" in
                arch)   sudo pacman -Rns --noconfirm "$pkg_name" ;;
                debian) sudo apt-get remove -y "$pkg_name" ;;
                fedora) sudo dnf remove -y "$pkg_name" ;;
            esac
            remove_status=$?
            ;;
        native)
            case "$app" in
                "Google Chrome")
                    case "$DISTRO" in
                        arch)   sudo pacman -Rns --noconfirm google-chrome-bin google-chrome 2>/dev/null || true ;;
                        debian) sudo apt-get remove -y google-chrome-stable ;;
                        fedora) sudo dnf remove -y google-chrome-stable ;;
                    esac
                    ;;
                "Brave")
                    case "$DISTRO" in
                        arch)   sudo pacman -Rns --noconfirm brave-bin brave 2>/dev/null || true ;;
                        debian) sudo apt-get remove -y brave-browser brave 2>/dev/null || true ;;
                        fedora) sudo dnf remove -y brave-browser brave 2>/dev/null || true ;;
                    esac
                    ;;
                "Zen Browser")
                    rm -rf "$HOME/.local/bin/zen" "$HOME/.local/bin/zen-browser" "$HOME/.local/share/zen-browser" "$HOME/.zen-browser" "$HOME/.config/zen-browser" /opt/zen-browser 2>/dev/null || true
                    ;;
                "Helium Browser")
                    sudo rm -f /opt/helium/helium /usr/local/bin/helium /usr/bin/helium 2>/dev/null || true
                    ;;
                "Opera")
                    case "$pkg_name" in
                        deb) sudo apt-get remove -y opera-stable opera-developer ;;
                        rpm) sudo dnf remove -y opera-stable opera-developer ;;
                        snap) sudo snap remove opera ;;
                    esac
                    ;;
                "OperaGx")
                    case "$pkg_name" in
                        deb) sudo apt-get remove -y opera-gx-stable opera-gx-developer ;;
                        rpm) sudo dnf remove -y opera-gx-stable opera-gx-developer ;;
                        snap) sudo snap remove opera-gx ;;
                    esac
                    ;;
                "LibreWolf")
                    case "$pkg_name" in
                        deb) sudo extrepo disable librewolf ;;
                        rpm) sudo dnf remove -y librewolf && sudo rm -f /etc/yum.repos.d/librewolf.repo ;;
                    esac
                    ;;
                "OBS Studio")
                    case "$pkg_name" in
                        deb) sudo apt-get remove -y obs-studio obs-studio-bin ;;
                        rpm) sudo dnf remove -y obs-studio obs-studio-bin ;;
                        snap) sudo snap remove obs-studio ;;
                    esac
                    ;;
                "Spotify")
                    case "$pkg_name" in
                        deb) sudo apt-get remove -y spotify-client ;;
                        rpm) sudo dnf remove -y spotify-client ;;
                        snap) sudo snap remove spotify ;;
                    esac
                    ;;
                "kdenlive")
                    case "$pkg_name" in
                        deb)  sudo apt-get remove -y kdenlive ;;
                        rpm)  sudo dnf remove -y kdenlive ;;
                        snap) sudo snap remove kdenlive ;;
                    esac
                    ;;
                "Discord")
                    case "$pkg_name" in
                        deb)  sudo apt-get remove -y discord ;;
                        rpm)  sudo dnf remove -y discord ;;
                        snap) sudo snap remove discord ;;
                    esac
                    ;;
                "Slack")
                    case "$pkg_name" in
                        deb)  sudo apt-get remove -y slack-desktop ;;
                        rpm)  sudo dnf remove -y slack ;;
                        snap) sudo snap remove slack ;;
                    esac
                    ;;
                "Telegram")
                    case "$pkg_name" in
                        deb)     sudo apt-get remove -y telegram-desktop ;;
                        rpm)     sudo dnf remove -y telegram-desktop ;;
                        snap)    sudo snap remove telegram-desktop ;;
                        tarball) sudo rm -rf /opt/telegram-desktop /usr/local/bin/telegram ;;
                    esac
                    ;;
                "Zoom")
                    case "$pkg_name" in
                        deb)  sudo apt-get remove -y zoom ;;
                        rpm)  sudo dnf remove -y zoom ;;
                        snap) sudo snap remove zoom-client ;;
                    esac
                    ;;
                "Inkscape")
                    case "$pkg_name" in
                        snap) sudo snap remove inkscape ;;
                    esac
                    ;;
                "LibreOffice")
                    case "$pkg_name" in
                        arch-fresh) sudo pacman -Rns --noconfirm libreoffice-fresh ;;
                        arch-still) sudo pacman -Rns --noconfirm libreoffice-still ;;
                        deb)        sudo apt-get remove -y libreoffice ;;
                        rpm)        sudo dnf remove -y libreoffice ;;
                        snap)       sudo snap remove libreoffice ;;
                    esac
                    ;;
                "GIMP")
                    case "$pkg_name" in
                        snap) sudo snap remove gimp ;;
                    esac
                    ;;
                "OpenRGB")
                    case "$pkg_name" in
                        deb)     sudo apt-get remove -y openrgb ;;
                        rpm)     sudo dnf remove -y openrgb ;;
                        flatpak) flatpak uninstall -y org.openrgb.OpenRGB ;;
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
            remove_status=$?
            ;;
        *)
            die "Unknown method '$method' for $app."
            ;;
    esac

    if [[ $remove_status -ne 0 ]]; then
        die "Failed to remove $app (method: $method, target: $pkg_name/$flatpak_id/$aur_pkg)."
    fi

    unset 'APP_SELECTED_METHODS[$app]'
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

    log_info "Installing $app using $(_target_label "$app" "$selected_target")..."

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

_download_file() {
    local url="$1"
    local output_path="$2"
    local ua="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36"

    # Codeberg's Anubis anti-bot flags spoofed browser UAs and forces a JS
    # proof-of-work challenge that curl/wget can't solve. Plain curl UA is
    # exempted, so skip the spoof for this host.
    if [[ "$url" == *"codeberg.org"* ]]; then
        if command -v curl >/dev/null 2>&1; then
            curl -fsSL --retry 3 --retry-delay 2 -o "$output_path" "$url" || return 1
        elif command -v wget >/dev/null 2>&1; then
            wget --progress=bar:force -O "$output_path" "$url" || return 1
        else
            log_warn "Neither curl nor wget is available. Installing curl first..."
            pkg_install curl || return 1
            curl -fsSL --retry 3 --retry-delay 2 -o "$output_path" "$url" || return 1
        fi
        return 0
    fi

    if command -v curl >/dev/null 2>&1; then
        curl -fsSL -A "$ua" --retry 3 --retry-delay 2 -o "$output_path" "$url" \
            || return 1
    elif command -v wget >/dev/null 2>&1; then
        wget --user-agent="$ua" --progress=bar:force -O "$output_path" "$url" \
            || return 1
    else
        log_warn "Neither curl nor wget is available. Installing curl first..."
        pkg_install curl || return 1
        curl -fsSL -A "$ua" --retry 3 --retry-delay 2 -o "$output_path" "$url" \
            || return 1
    fi
}


_install_native_app() {
    local app="$1"
    case "$app" in
        "Google Chrome")
            case "$DISTRO" in
                arch)
                    require_aur_helper
                    aur_install google-chrome-bin \
                        || die "Failed to install Google Chrome via AUR."
                    ;;
                debian)
                    log_info "Downloading Google Chrome (.deb) from Google's direct repository..."
                    _download_file \
                        "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb" \
                        /tmp/google-chrome.deb \
                        || die "Failed to download Google Chrome."
                    sudo dpkg -i /tmp/google-chrome.deb 2>/dev/null || true
                    sudo apt-get install -f -y \
                        || die "Failed to fix Google Chrome dependencies."
                    rm -f /tmp/google-chrome.deb
                    ;;
                fedora)
                    log_info "Downloading Google Chrome (.rpm) from Google's direct repository..."
                    _download_file \
                        "https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm" \
                        /tmp/google-chrome.rpm \
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
        "Brave")
            case "$DISTRO" in
                arch)
                    require_aur_helper
                    aur_install brave-bin \
                        || die "Failed to install Brave via AUR."
                    ;;
                debian)
                    log_info "Installing Brave via official script..."
                    curl -fsS https://dl.brave.com/install.sh | sh \
                        || die "Failed to install Brave via official script."
                    ;;
                fedora)
                    log_info "Installing Brave via official script..."
                    curl -fsS https://dl.brave.com/install.sh | sh \
                        || die "Failed to install Brave via official script."
                    ;;
                *)
                    die "Unsupported distro for Brave: $DISTRO"
                    ;;
            esac
            ;;
        "Zen Browser")
            case "$DISTRO" in
                arch)
                    require_aur_helper
                    aur_install zen-browser-bin \
                        || die "Failed to install Zen Browser via AUR."
                    ;;
                debian|fedora)
                    log_info "Installing Zen Browser via official script..."
                    curl -fsSL https://github.com/zen-browser/updates-server/raw/refs/heads/main/install.sh | bash \
                        || die "Failed to install Zen Browser."
                    ;;
                *)
                    die "Unsupported distro for Zen Browser: $DISTRO"
                    ;;
            esac
            ;;
        "OperaGx")
            case "$DISTRO" in
               deb)
                    log_info "Installing Opera GX via native way"
                    tmpfile="$(mktemp --suffix=.deb)"
                    curl -fsSL \
                        "https://download.opera.com/download/get/?partner=www&opsys=Linux&product=Opera+GX" \
                        -o "$tmpfile" \
                        || die "Failed to download Opera GX."
                    sudo dpkg -i "$tmpfile" \
                        || sudo apt-get install -f -y \
                        || die "Failed to install Opera GX."
                    rm -f "$tmpfile"
                    ;;
                rpm)
                    log_info "Installing Opera GX via native way"

                    tmpfile="$(mktemp --suffix=.rpm)"

                    curl -fsSL \
                        "https://download.opera.com/download/get/?partner=www&opsys=Linux&product=Opera+GX&package=RPM" \
                        -o "$tmpfile" \
                        || die "Failed to download Opera GX."

                    if command -v dnf >/dev/null 2>&1; then
                        sudo dnf install -y "$tmpfile"
                    elif command -v zypper >/dev/null 2>&1; then
                        sudo zypper --non-interactive install "$tmpfile"
                    else
                        sudo rpm -Uvh "$tmpfile"
                    fi || die "Failed to install Opera GX."

                    rm -f "$tmpfile"
                    ;;
                snap)
                    if ! _can_use_snap; then
                        die "Snap is not installed or enabled. Install snapd and enable it first."
                    fi
                    log_info "Installing Opera GX via Snap..."
                    sudo snap install opera-gx \
                        || die "Failed to install Opera GX via Snap."
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
            case "$pkg_name" in
                deb)
                    log_info "Adding Opera's official APT repository..."
                    if ! command -v gpg >/dev/null 2>&1; then
                        pkg_install gnupg || die "Failed to install gnupg for Opera's signing key."
                    fi
                    sudo mkdir -p /usr/share/keyrings
                    curl -fsSL https://deb.opera.com/archive.key \
                        | sudo gpg --dearmor --yes -o /usr/share/keyrings/opera-browser.gpg \
                        || die "Failed to import Opera's GPG key."

                    echo "deb [signed-by=/usr/share/keyrings/opera-browser.gpg] https://deb.opera.com/opera-stable/ stable non-free" \
                        | sudo tee /etc/apt/sources.list.d/opera-stable.list > /dev/null

                    sudo DEBIAN_FRONTEND=noninteractive apt-get update \
                        || die "Failed to refresh APT after adding Opera's repository."
                    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y opera-stable \
                        || die "Failed to install Opera via APT."
                    ;;
                rpm)
                    log_info "Adding Opera's official DNF repository..."
                    sudo rpm --import https://rpm.opera.com/rpmrepo.key \
                        || die "Failed to import Opera's RPM signing key."

                    sudo tee /etc/yum.repos.d/opera.repo > /dev/null << 'EOF'
[opera]
name=Opera packages
type=rpm-md
baseurl=https://rpm.opera.com/rpm
gpgcheck=1
gpgkey=https://rpm.opera.com/rpmrepo.key
enabled=1
EOF

                    sudo dnf install -y opera-stable \
                        || die "Failed to install Opera via DNF."
                    ;;
                snap)
                    if ! _can_use_snap; then
                        die "Snap is not installed or enabled. Install snapd and enable it first."
                    fi
                    sudo snap install opera \
                        || die "Failed to install Opera via Snap."
                    ;;
                *)
                    die "Unsupported Opera package source: $pkg_name"
                    ;;
            esac
            ;;
        "LibreWolf")
            case "$pkg_name" in
                deb)
                    log_info "Enabling LibreWolf's official repo via extrepo..."
                    sudo apt-get update \
                        || die "Failed to refresh APT before enabling extrepo."
                    sudo apt-get install -y extrepo \
                        || die "Failed to install extrepo."
                    sudo extrepo enable librewolf \
                        || die "Failed to enable LibreWolf's extrepo repository."
                    sudo apt-get update \
                        || die "Failed to refresh APT after enabling LibreWolf's repository."
                    sudo apt-get install -y librewolf \
                        || die "Failed to install LibreWolf via APT."
                    ;;
                rpm)
                    log_info "Adding LibreWolf's official DNF repository..."
                    sudo dnf config-manager addrepo --from-repofile=https://repo.librewolf.net/librewolf.repo \
                        || die "Failed to add LibreWolf's DNF repository."
                    sudo dnf install -y librewolf \
                        || die "Failed to install LibreWolf via DNF."
                    ;;
                *)
                    die "Unsupported LibreWolf package source: $pkg_name"
                    ;;
            esac
            ;;
        "OBS Studio")
            case "$pkg_name" in
                deb)
                    log_info "Installing OBS Studio via APT..."
                    sudo apt-get update \
                        || die "Failed to refresh APT before installing OBS Studio."
                    sudo apt-get install -y obs-studio \
                        || die "Failed to install OBS Studio via APT."
                    ;;
                rpm)
                    log_info "Installing OBS Studio via DNF..."
                    sudo dnf install -y obs-studio \
                        || die "Failed to install OBS Studio via DNF."
                    ;;
                snap)
                    if ! _can_use_snap; then
                        die "Snap is not installed or enabled. Install snapd and enable it first."
                    fi
                    sudo snap install obs-studio \
                        || die "Failed to install OBS Studio via Snap."
                    ;;
                *)
                    die "Unsupported OBS Studio package source: $pkg_name"
                    ;;
            esac
            ;;
        "Spotify")
            case "$pkg_name" in
                deb)
                    log_info "Adding Spotify's official APT repository..."
                    curl -sS https://download.spotify.com/debian/pubkey_6224F9941A8AA6D1.gpg \
                        | sudo gpg --dearmor --yes -o /usr/share/keyrings/spotify-archive-keyring.gpg \
                        || die "Failed to import Spotify's GPG key."
                    echo "deb [signed-by=/usr/share/keyrings/spotify-archive-keyring.gpg] http://repository.spotify.com stable non-free" \
                        | sudo tee /etc/apt/sources.list.d/spotify.list > /dev/null
                    sudo apt-get install -y spotify-client || die "Failed to install Spotify via APT."
                    ;;
                rpm)
                    log_info "Adding Spotify's official DNF repository..."
                    sudo dnf config-manager --add-repo=https://negativo17.org/repos/spotify
                    sudo dnf install -y spotify-client || die "Failed to install Spotify via DNF."
                    ;;
                snap)
                    if ! _can_use_snap; then
                        die "Snap is not installed or enabled. Install snapd and enable it first."
                    fi
                    sudo snap install spotify || die "Failed to install Spotify via Snap."
                    ;;
                *)
                    die "Unsupported Spotify package source: $pkg_name"
                    ;;
            esac
            ;;
        "kdenlive")
            case "$pkg_name" in
                deb)
                    log_info "Installing kdenlive via APT..."
                    sudo apt-get install -y kdenlive || die "Failed to install kdenlive via APT."
                    ;;
                rpm)
                    log_info "Installing kdenlive via DNF..."
                    sudo dnf install -y kdenlive || die "Failed to install kdenlive via DNF."
                    ;;
                snap)
                    if ! _can_use_snap; then
                        die "Snap is not installed or enabled. Install snapd and enable it first."
                    fi
                    sudo snap install kdenlive || die "Failed to install kdenlive via Snap."
                    ;;
                *)
                    die "Unsupported kdenlive package source: $pkg_name"
                    ;;
            esac
            ;;
        "Discord")
            case "$pkg_name" in
                deb)
            log_info "Downloading Discord (.deb) from Discord's official servers..."
            _download_file \
                "https://discord.com/api/download?platform=linux&format=deb" \
                /tmp/discord.deb \
                || die "Failed to download Discord."
            sudo dpkg -i /tmp/discord.deb 2>/dev/null || true
            sudo apt-get install -f -y \
                || die "Failed to fix Discord dependencies."
            rm -f /tmp/discord.deb
            ;;
                rpm)
            log_info "Downloading Discord (.rpm) from Discord's official servers..."
            _download_file \
                "https://discord.com/api/download?platform=linux&format=rpm" \
                /tmp/discord.rpm \
                || die "Failed to download Discord."
            sudo dnf install -y /tmp/discord.rpm \
                || die "Failed to install Discord."
            rm -f /tmp/discord.rpm
            ;;
                snap)
                    if ! _can_use_snap; then
                        die "Snap is not installed or enabled. Install snapd and enable it first."
                    fi
                    sudo snap install discord || die "Failed to install Discord via Snap."
            ;;
                *)
                    die "Unsupported Discord package source: $pkg_name"
                    ;;
            esac
            ;;
        "Thunderbird")
            case "$DISTRO" in
                arch)   pkg_install thunderbird ;;
                debian) pkg_install thunderbird ;;
                fedora) pkg_install thunderbird ;;
                snap)  sudo snap install thunderbird || die "Failed to install Thunderbird via Snap." ;;
            esac
            ;;
        "Teams")
            case "$pkg_name" in
                deb)
                    log_info "Adding teams-for-linux's official APT repository..."
                    sudo mkdir -p /etc/apt/keyrings
                    curl -fsSL https://repo.teamsforlinux.de/teams-for-linux.asc \
                        | sudo tee /etc/apt/keyrings/teams-for-linux.asc > /dev/null \
                        || die "Failed to import teams-for-linux's signing key."
                    echo "deb [signed-by=/etc/apt/keyrings/teams-for-linux.asc arch=$(dpkg --print-architecture)] https://repo.teamsforlinux.de/debian/ stable main" \
                        | sudo tee /etc/apt/sources.list.d/teams-for-linux.list > /dev/null
                    sudo apt-get update \
                        || die "Failed to refresh APT after adding teams-for-linux's repository."
                    sudo apt-get install -y teams-for-linux || die "Failed to install teams-for-linux via APT."
                    ;;
                rpm)
                    log_info "Adding teams-for-linux's official DNF repository..."
                    curl -fsSL https://repo.teamsforlinux.de/teams-for-linux.asc -o /tmp/teams-for-linux.asc \
                        || die "Failed to download teams-for-linux's signing key."
                    sudo rpm --import /tmp/teams-for-linux.asc \
                        || die "Failed to import teams-for-linux's signing key."
                    rm -f /tmp/teams-for-linux.asc
                    sudo curl -fsSL -o /etc/yum.repos.d/teams-for-linux.repo https://repo.teamsforlinux.de/rpm/teams-for-linux.repo \
                        || die "Failed to add teams-for-linux's DNF repository."
                    sudo dnf install -y teams-for-linux || die "Failed to install teams-for-linux via DNF."
                    ;;
                snap)
                    if ! _can_use_snap; then
                        die "Snap is not installed or enabled. Install snapd and enable it first."
                    fi
                    sudo snap install teams-for-linux || die "Failed to install teams-for-linux via Snap."
                    ;;
                *)
                    die "Unsupported Teams package source: $pkg_name"
                    ;;
            esac
            ;;
        "Slack")
            case "$pkg_name" in
                deb)
                    log_info "Adding Slack's official APT repository..."
                    curl -fsSL https://packagecloud.io/slacktechnologies/slack/gpgkey \
                        | sudo gpg --dearmor --yes -o /usr/share/keyrings/slack-archive-keyring.gpg \
                        || die "Failed to import Slack's GPG key."
                    echo "deb [signed-by=/usr/share/keyrings/slack-archive-keyring.gpg] https://packagecloud.io/slacktechnologies/slack/debian/ jessie main" \
                        | sudo tee /etc/apt/sources.list.d/slack.list > /dev/null
                    sudo apt-get update \
                        || die "Failed to refresh APT after adding Slack's repository."
                    sudo apt-get install -y slack-desktop || die "Failed to install Slack via APT."
                    ;;
                rpm)
                    log_info "Adding Slack's official DNF repository..."
                    sudo tee /etc/yum.repos.d/slack.repo > /dev/null << 'EOF'
[slack]
name=Slack
baseurl=https://packagecloud.io/slacktechnologies/slack/fedora/21/$basearch
enabled=1
gpgcheck=1
gpgkey=https://packagecloud.io/slacktechnologies/slack/gpgkey
EOF
                    sudo dnf install -y slack || die "Failed to install Slack via DNF."
                    ;;
                snap)
                    if ! _can_use_snap; then
                        die "Snap is not installed or enabled. Install snapd and enable it first."
                    fi
                        sudo snap install slack || die "Failed to install Slack via Snap."
                    ;;
                *)
                    die "Unsupported Slack package source: $pkg_name"
                    ;;
            esac
            ;;
        "Telegram")
            case "$pkg_name" in
                deb)
                    log_info "Installing telegram-desktop via APT..."
                    sudo apt-get update \
                        || die "Failed to refresh APT before installing Telegram."
                    sudo apt-get install -y telegram-desktop \
                        || die "Failed to install Telegram via APT (package may be unavailable on this release — try the tarball or Snap option instead)."
                    ;;
                rpm)
                    log_info "Enabling RPM Fusion Free and installing telegram-desktop via DNF..."
                    sudo dnf install -y "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
                        || die "Failed to enable RPM Fusion Free."
                    sudo dnf install -y telegram-desktop || die "Failed to install Telegram via DNF."
                    ;;
                snap)
                    if ! _can_use_snap; then
                        die "Snap is not installed or enabled. Install snapd and enable it first."
                    fi
                    sudo snap install telegram-desktop || die "Failed to install Telegram via Snap."
                    ;;
                tarball)
                    log_info "Downloading the official Telegram Desktop tarball..."
                    _download_file "https://telegram.org/dl/desktop/linux" /tmp/tsetup.tar.xz \
                        || die "Failed to download Telegram."
                    rm -rf /tmp/Telegram
                    tar -xf /tmp/tsetup.tar.xz -C /tmp || die "Failed to extract Telegram."
                    sudo mkdir -p /opt/telegram-desktop
                    sudo cp -r /tmp/Telegram/. /opt/telegram-desktop/
                    sudo ln -sf /opt/telegram-desktop/Telegram /usr/local/bin/telegram
                    rm -rf /tmp/tsetup.tar.xz /tmp/Telegram
                    ;;
                *)
                    die "Unsupported Telegram package source: $pkg_name"
                    ;;
            esac
            ;;
        "Zoom")
            case "$pkg_name" in
                deb)
                    log_info "Downloading Zoom (.deb) from Zoom's official servers..."
                    _download_file \
                        "https://zoom.us/client/latest/zoom_amd64.deb" \
                        /tmp/zoom_amd64.deb \
                        || die "Failed to download Zoom."
                    sudo apt-get install -y /tmp/zoom_amd64.deb \
                        || die "Failed to install Zoom via APT."
                    rm -f /tmp/zoom_amd64.deb
                    ;;
                rpm)
                    log_info "Downloading Zoom (.rpm) from Zoom's official servers..."
                    _download_file \
                     "https://zoom.us/client/latest/zoom_x86_64.rpm" \
                        /tmp/zoom_x86_64.rpm \
                        || die "Failed to download Zoom."
                    sudo dnf install -y /tmp/zoom_x86_64.rpm \
                        || die "Failed to install Zoom via DNF."
                    rm -f /tmp/zoom_x86_64.rpm
                    ;;
                snap)
                    if ! _can_use_snap; then
                        die "Snap is not installed or enabled. Install snapd and enable it first."
                    fi
                    sudo snap install --classic zoom-client || die "Failed to install Zoom via Snap."
                    ;;
                *)
                    die "Unsupported Zoom package source: $pkg_name"
                    ;;
            esac
            ;;
        "Inkscape")
            case "$pkg_name" in
                snap)
                    if ! _can_use_snap; then
                        die "Snap is not installed or enabled. Install snapd and enable it first."
                    fi
                    sudo snap install inkscape || die "Failed to install Inkscape via Snap."
                    ;;
                *)
                    die "Unsupported Inkscape package source: $pkg_name"
                    ;;
            esac
            ;;
        "LibreOffice")
            case "$pkg_name" in
                arch-fresh)
                    sudo pacman -S --noconfirm libreoffice-fresh || die "Failed to install LibreOffice Fresh."
                    ;;
                arch-still)
                    sudo pacman -S --noconfirm libreoffice-still || die "Failed to install LibreOffice Still."
                    ;;
                deb)
                    log_info "Installing LibreOffice via APT..."
                    sudo apt-get update \
                        || die "Failed to refresh APT before installing LibreOffice."
                    sudo apt-get install -y libreoffice || die "Failed to install LibreOffice via APT."
                    ;;
                rpm)
                    log_info "Installing LibreOffice via DNF..."
                    sudo dnf install -y libreoffice || die "Failed to install LibreOffice via DNF."
                    ;;
                snap)
                    if ! _can_use_snap; then
                        die "Snap is not installed or enabled. Install snapd and enable it first."
                    fi
                    sudo snap install libreoffice || die "Failed to install LibreOffice via Snap."
                    ;;
                *)
                    die "Unsupported LibreOffice package source: $pkg_name"
                    ;;
            esac
            ;;
        "GIMP")
            case "$pkg_name" in
                snap)
                    if ! _can_use_snap; then
                        die "Snap is not installed or enabled. Install snapd and enable it first."
                    fi
                    sudo snap install gimp || die "Failed to install GIMP via Snap."
                    ;;
                *)
                    die "Unsupported GIMP package source: $pkg_name"
                    ;;
            esac
            ;;
        "OpenRGB")
            case "$pkg_name" in
                deb)
                    log_info "Downloading OpenRGB (.deb) from official releases..."
                    _download_file \
                        "https://codeberg.org/OpenRGB/OpenRGB/releases/download/release_candidate_1.0rc3/openrgb_1.0rc3_amd64_trixie_6fbcf62.deb" \
                        /tmp/openrgb.deb \
                        || die "Failed to download OpenRGB."
                    sudo dpkg -i /tmp/openrgb.deb 2>/dev/null || true
                    sudo apt-get install -f -y \
                        || die "Failed to fix OpenRGB dependencies."
                    rm -f /tmp/openrgb.deb
                    ;;
                rpm)
                    log_info "Downloading OpenRGB (.rpm) from official releases..."
                    _download_file \
                        "https://codeberg.org/OpenRGB/OpenRGB/releases/download/release_candidate_1.0rc3/openrgb_1.0rc3_x86_64_f43_6fbcf62.rpm" \
                        /tmp/openrgb.rpm \
                        || die "Failed to download OpenRGB."
                    sudo dnf install -y /tmp/openrgb.rpm \
                        || die "Failed to install OpenRGB."
                    rm -f /tmp/openrgb.rpm
                    ;;
                flatpak)
                    flatpak install -y flathub org.openrgb.OpenRGB \
                        || die "Failed to install OpenRGB via Flatpak."
                    ;;
                *)
                    die "Unsupported OpenRGB package source: $pkg_name"
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
