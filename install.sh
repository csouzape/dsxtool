#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
RC='\033[0m'

check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}Error: Please run as root${RC}"
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
                echo -e "${RED}Unsupported distro: $ID${RC}"
                exit 1
                ;;
        esac
    else
        echo -e "${RED}Cannot determine distro${RC}"
        exit 1
    fi
}

run_script() {
    local script_path="$1"
    
    if [ ! -f "$script_path" ]; then
        echo -e "${RED}Error: Script not found: $script_path${RC}"
        read -p "Press Enter to continue..."
        return 1
    fi
    
    echo -e "${BLUE}Running: $script_path${RC}"
    if ! bash "$script_path"; then
        echo -e "${RED}Error: Script failed: $script_path${RC}"
        read -p "Press Enter to continue..."
        return 1
    fi
    
    echo -e "${GREEN}Script completed successfully!${RC}"
    echo ""
    read -p "Press Enter to continue..."
}

main() {
    # Verificações iniciais
    check_root
    check_distro
    
    while true; do
        clear
        echo -e "${CYAN}================================${RC}"
        echo -e "${MAGENTA}      DSXTool - $DISTRO Edition${RC}"
        echo -e "${CYAN}================================${RC}"
        echo -e "${YELLOW}Detected distro: ${GREEN}$DISTRO${RC}"
        echo ""
        echo -e "${BLUE}1)${RC} Install TLP (Battery Optimization)"
        echo -e "${BLUE}2)${RC} Install Fastfetch"
        echo -e "${BLUE}3)${RC} Remove Fastfetch"
        echo -e "${BLUE}4)${RC} Gaming Setup"
        echo -e "${BLUE}5)${RC} Install My Apps"
        echo -e "${RED}6)${RC} Exit"
        echo ""
        read -p "$(echo -e ${YELLOW}Enter your choice:${RC} )" choice
        
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
                echo -e "${GREEN}Exiting...${RC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid choice. Please try again.${RC}"
                sleep 2
                ;;
        esac
    done
}

main