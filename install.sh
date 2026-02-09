# this is install script 

check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo "Please run as root"
        exit 1
    fi
}

check_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        case "$ID" in
            ubuntu|debian|arch|fedora)
                DISTRO="$ID"
                ;;
            *)
                echo "Unsupported distro: $ID"
                exit 1
                ;;
        esac
    else
        echo "Cannot determine distro"
        exit 1
    fi
}
main(){
    while true; do
        echo "Choice the script"
        echo "1) TLP"
        echo "2) Fastfetch"
        echo "3) Exit"
        read -p "Enter your choice: " choice
        case $choice in
            1)
                check_root
                check_distro
                bash core/$DISTRO/tlp.sh
                ;;
            2)
                check_root
                check_distro
                bash core/$DISTRO/fastfetch.sh
                ;;
            3)
                echo "Exiting..."
                exit 0
                ;;
            *)
                echo "Invalid choice. Please try again."
                ;;
        esac
    done
}
main