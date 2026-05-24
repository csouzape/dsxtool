#!/bin/bash

REPO_URL="https://github.com/csouzape/sober-config.git"
TMP_DIR="/tmp/sober-optimizer"

run_sober_optimizer() {
    if [ -d "$TMP_DIR" ]; then
        rm -rf "$TMP_DIR"
    fi

    git clone "$REPO_URL" "$TMP_DIR"

    chmod +x "$TMP_DIR/install.sh"
    bash "$TMP_DIR/install.sh"
}

run_sober_optimizer