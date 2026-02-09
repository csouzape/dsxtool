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
    mkdir -p "${HOME}/.config/fastfetch"

    if command -v curl &>/dev/null; then
        curl -fsSL \
          -o "${HOME}/.config/fastfetch/config.jsonc" \
          https://raw.githubusercontent.com/ChrisTitusTech/mybash/main/config.jsonc
        echo "Fastfetch configured successfully."
    else
        echo "curl not found, skipping configuration"
    fi
}
setup(){
    mkdir -p "${HOME}/.bashrc"
    echo "source ${HOME}/.bashrc" >> "${HOME}/.bashrc"
    echo "source ${HOME}/.bashrc" >> "${HOME}/.bash_profile"
}

main(){
    check
    fastfetch_install
    configure
    setup

}
main
