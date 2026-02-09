#!/bin/bash
install_flatpak_apps(){
     local app_id="$1" 
    if flatpak list --app | grep -q "$app_id"; then 
        return 0 
    else
        return 1  
    fi
    
if is_flatpak_installed "com.spotify.Client"; then
        echo "Spotify has installed."
    else
        echo "Instalando Spotify..."
        flatpak install -y flathub com.spotify.Client
    fi

    if is_flatpak_installed "com.discordapp.Discord"; then
        echo "Discord has installed."
    else
        echo "Instalando Discord..."
        flatpak install -y flathub com.discordapp.Discord
    fi

    if is_flatpak_installed "com.stremio.Stremio"; then
        echo "Stremio has installed."
    else
        echo "Instalando Stremio..."
        flatpak install -y flathub com.stremio.Stremio
    fi
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

