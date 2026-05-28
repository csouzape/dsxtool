#!/bin/bash
set -euo pipefail 

pkg_uṕdate() {
    read -rp "Do you want to update the system? [y/N] " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        echo "Updating the system..."
        sudo apt update && sudo apt upgrade -y
        echo "System updated successfully."
    else
        echo "System update skipped."
    fi

}

pkg_install() {
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        echo "Install packages..."
        
        source /etc/os-release

        case "$ID" in
            ubuntu|debian)
                sudo apt install -y
                ;;
            fedora)
                sudo dnf install -y package1 package2 package3
                ;;
            arch)
                sudo pacman -S --noconfirm package1 package2 package3
                ;;
            *)
                echo "Unsupported distribution: $ID"
                exit 1
                ;;
        esac


}

pkg_remove() {
    
}