#!/bin/bash

HOME="$HOME"

check(){
    command -v fastfetch &>/dev/null
}

fastfetch_install(){
    if check; then
        echo "Fastfetch is already installed"
        return
    else
        echo "Installing Fastfetch..."
        sudo dnf install -y fastfetch
    fi
}

configure(){
    mkdir -p "$HOME/.config/fastfetch"

    if command -v curl &>/dev/null; then
        curl -fsSL \
          -o "$HOME/.config/fastfetch/config.jsonc" \
          https://raw.githubusercontent.com/ChrisTitusTech/mybash/main/config.jsonc
        echo "Fastfetch configured successfully."
    else
        echo "curl not found, skipping configuration"
    fi
}

setup(){
    # Adiciona fastfetch ao .bashrc se ainda não estiver lá
    if ! grep -q "fastfetch" "$HOME/.bashrc"; then
        echo "fastfetch" >> "$HOME/.bashrc"
    fi
    
    # Adiciona source do .bashrc ao .bash_profile se ainda não estiver lá
    if ! grep -q "source.*\.bashrc" "$HOME/.bash_profile" 2>/dev/null; then
        echo "source $HOME/.bashrc" >> "$HOME/.bash_profile"
    fi
}

main(){
    fastfetch_install
    configure
    setup
    echo "Setup completed!"
}

main