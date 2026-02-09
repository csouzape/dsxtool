#!/bin/bash

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

run_script() {
    local script_path="$1"
    
    if [ ! -f "$script_path" ]; then
        echo "Error: Script not found: $script_path"
        read -p "Press Enter to continue..."
        return 1
    fi
    
    if ! bash "$script_path"; then
        echo "Error: Script failed: $script_path"
        read -p "Press Enter to continue..."
        return 1
    fi
    
    echo ""
    read -p "Press Enter to continue..."
}

main() {
    # Verificações iniciais
    check_root
    check_distro
    
    while true; do
        clear
        echo "================================"
        echo "      DSXTool - $DISTRO Edition"
        echo "================================"
        echo "Detected distro: $DISTRO"
        echo ""
        echo "1) Install TLP (Battery Optimization)"
        echo "2) Install Fastfetch"
        echo "3) Remove Fastfetch"
        echo "4) Gaming Setup"
        echo "5) Install My Apps"
        echo "6) Exit"
        echo ""
        read -p "Enter your choice: " choice
        
        case $choice in
            1)
                run_script "core/$DISTRO/tlp.sh"
                ;;
            2)
                run_script "core/$DISTRO/fastfetch.sh"
                ;;
            3)
                run_script "core/$DISTRO/fastfetch_remove.sh"
                ;;
            4)
                run_script "core/$DISTRO/gaming-setup.sh"
                ;;
            5)
                run_script "core/$DISTRO/install_my_apps.sh"
                ;;
            6)
                echo "Exiting..."
                exit 0
                ;;
            *)
                echo "Invalid choice. Please try again."
                sleep 2
                ;;
        esac
    done
}

main