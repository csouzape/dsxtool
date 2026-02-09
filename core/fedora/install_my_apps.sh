#!/bin/bash
install_flatpak_apps(){
    echo "Installing Flatpak apps..."
    flatpak install -y flathub com.spotify.Client
    flatpak install -y flathub com.visualstudio.code
    flatpak install -y flathub com.discordapp.Discord
    flatpak install -y flathub com.io.github.shiftey.Desktop
    echo "Flatpak apps installed successfully."
}

install_browser(){
    if command -v google-chrome &> /dev/null; then
        echo "Google Chrome já está instalado."
        return 0
    fi

    if ! curl -O https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm; then
        echo "Erro ao baixar o Google Chrome."
        return 1
    fi
    
    if ! sudo dnf install -y google-chrome-stable_current_x86_64.rpm; then
        echo "Erro ao instalar o Google Chrome."
        rm -f google-chrome-stable_current_x86_64.rpm
        return 1
    fi
    
    rm -f google-chrome-stable_current_x86_64.rpm
    echo "Google Chrome installed successfully."
}


main(){
    install_flatpak_apps
    install_browser
    echo "All applications installed successfully."
}
main

