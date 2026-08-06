#!/usr/bin/env bash

install() {
    local repo_dir
    local install_script

    repo_dir=$(mktemp -d) || return 1

    echo "Installing Sober optimization..."
    git clone "https://github.com/csouzape/sober-config" "$repo_dir" || {
        echo "Failed to clone sober-config repository." >&2
        rm -rf "$repo_dir"
        return 1
    }

    install_script="$repo_dir/install.sh"
    if [[ ! -f "$install_script" ]]; then
        echo "install.sh not found in sober-config repository." >&2
        rm -rf "$repo_dir"
        return 1
    fi

    chmod +x "$install_script"

    if [[ -e /dev/tty ]]; then
        bash "$install_script" </dev/tty 2>&1 || {
            echo "Sober optimization installation failed." >&2
            rm -rf "$repo_dir"
            return 1
        }
    else
        bash "$install_script" || {
            echo "Sober optimization installation failed." >&2
            rm -rf "$repo_dir"
            return 1
        }
    fi

    rm -rf "$repo_dir"
}
