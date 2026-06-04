#!/bin/bash
REPO="https://github.com/csouzape/sober-config" # GitHub repository URL

install() {
    local repo_dir
    repo_dir=$(mktemp -d)

    git clone "$REPO" "$repo_dir" || return 1
    pushd "$repo_dir" >/dev/null || return 1
    chmod +x install.sh
    if [[ -t 0 && -e /dev/tty ]]; then
        bash ./install.sh </dev/tty >/dev/tty || return 1
    else
        bash ./install.sh || return 1
    fi
    popd >/dev/null || return 1
    rm -rf "$repo_dir"
}