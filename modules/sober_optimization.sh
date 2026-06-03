#!/bin/bash
REPO="https://github.com/csouzape/sober-config" # GitHub repository URL

install() {
    local repo_dir
    repo_dir=$(basename "$REPO" .git)

    if [[ ! -d "$repo_dir" ]]; then
        git clone "$REPO" "$repo_dir" || return 1
    fi

    pushd "$repo_dir" >/dev/null || return 1
    chmod +x install.sh
    ./install.sh
    popd >/dev/null || return 1
}