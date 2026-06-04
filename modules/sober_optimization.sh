#!/bin/bash
REPO="https://github.com/csouzape/sober-config" # GitHub repository URL

install() {
    local repo_dir
    repo_dir=$(mktemp -d)

    git clone "$REPO" "$repo_dir" || return 1
    pushd "$repo_dir" >/dev/null || return 1
    chmod +x install.sh
    bash ./install.sh </dev/tty >/dev/tty || return 1
    popd >/dev/null || return 1
    rm -rf "$repo_dir"
}