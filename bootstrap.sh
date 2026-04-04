#!/usr/bin/env bash
set -euo pipefail

REPO="https://github.com/csouzape/dsxtool.git"
INSTALL_DIR="$HOME/.local/share/dsxtool"

if ! command -v git >/dev/null 2>&1; then
    echo "[INFO] git not found. Installing..."
    if command -v pacman >/dev/null 2>&1; then
        sudo pacman -S --noconfirm --needed git
    elif command -v apt >/dev/null 2>&1; then
        sudo apt install -y git
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y git
    else
        echo "[ERROR] Cannot install git. Please install it manually."
        exit 1
    fi
fi

if [[ -d "$INSTALL_DIR/.git" ]]; then
    echo "[INFO] Updating dsxtool..."
    git -C "$INSTALL_DIR" fetch origin
    if ! git -C "$INSTALL_DIR" pull --ff-only origin main; then
        echo "[ERROR] Fast-forward update failed. Local changes may exist in $INSTALL_DIR."
        echo "[ERROR] Resolve manually or remove the directory and run bootstrap again."
        exit 1
    fi
else
    echo "[INFO] Installing dsxtool..."
    rm -rf "$INSTALL_DIR"
    git clone "$REPO" "$INSTALL_DIR"
fi

if [[ ! -f "$INSTALL_DIR/install.sh" ]]; then
    echo "[ERROR] install.sh not found."
    exit 1
fi

exec bash "$INSTALL_DIR/install.sh"