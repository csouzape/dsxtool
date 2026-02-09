check(){
    if [ -f /usr/bin/fastfetch ]; then
        echo "Fastfetch is already installed"
        exit 0
    fi
} 
fastfetch_install(){
    echo "Installing Fastfetch..."
    if [ -f /usr/bin/fastfetch ]; then
        echo "Fastfetch is already installed"
        exit 0
    fi
    sudo dnf install fastfetch -y
    echo "Fastfetch installed successfully."
}
configure(){
    mkdir -p "${HOME}/.config/fastfetch"
    curl -sSLo "${HOME}/.config/fastfetch/config.jsonc" https://raw.githubusercontent.com/ChrisTitusTech/mybash/main/config.jsonc
    echo "Fastfetch configured successfully."

}
setup(){
    mkdir -p "${HOME}/.bashrc"
    echo "source ${HOME}/.bashrc" >> "${HOME}/.bashrc"
    echo "source ${HOME}/.bashrc" >> "${HOME}/.bash_profile"
    echo "Fastfetch setup completed successfully."

}

main(){
    check
    fastfetch_install
    configure
    setup

}
main
