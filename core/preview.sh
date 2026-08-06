#!/usr/bin/env bash

get_preview() {
    local item="$1"
    case "$item" in
        "Setup Alias")
            echo "Sets up a convenient alias for dsxtool."
            echo
            echo "  • Adds 'alias dsxtool=\'curl -fsSL https://raw.githubusercontent.com/csouzape/dsxtool/main/bootstrap.sh | bash\'' to your shell config"
            echo "  • Supports Bash, Zsh, Fish, Ksh and other shells"
            echo "  • Prompts to remove existing alias if found"
            ;;
        "Update System")
            echo "Runs a full system package upgrade."
            echo
            echo "  pacman -Syu (Arch)"
            echo "  dnf upgrade (Fedora)"
            echo "  apt upgrade (Debian)"
            ;;
        "Install TLP")
            echo "Battery & power management for laptops."
            echo
            echo "  • Replaces power-profiles-daemon"
            echo "  • CPU and battery tuning"
            ;;
        "Install Apps")
            echo "Install apps by category:"
            echo
            echo "  • Browsers, Media, Communication"
            echo "  • Productivity, Gaming"
            echo "  • System Tools, Terminals, Development"
            ;;
        "Change Desktop Environment")
            echo "Install a new desktop environment."
            echo
            echo "  KDE · XFCE · Hyprland · Cosmic"
            echo "  Hyprland csouzape edition"
            ;;
        "Fonts Downloader")
            echo "Install curated Nerd Fonts collection."
            echo
            echo "  • Terminal and IDE icon fonts"
            ;;
        "Setup Flatpak")
            echo "Installs Flatpak + Flathub remote."
            echo
            echo "  • Enables sandboxed app distribution"
            ;;
        "Setup Virtualization")
            echo "Installs KVM/QEMU or VirtualBox."
            echo
            echo "  • virt-manager GUI"
            echo "  • libvirt + virtnetworkd"
            echo "  • Or VirtualBox with guest additions"
            ;;
        "Setup Shell")
            echo "Configure your shell environment."
            echo
            echo "  • Zsh + oh-my-zsh"
            echo "  • Fish + fisher"
            echo "  • Plugins and prompt setup"
            ;;
        "Setup Gaming")
            echo "Full gaming environment setup."
            echo
            echo "  • Wine + gaming libraries"
            echo "  • Steam + Lutris"
            echo "  • MangoHud + GameMode"
            ;;
        "Setup Bluetooth")
            echo "Installs and configures Bluetooth."
            echo
            echo "  • bluez + bluez-utils"
            echo "  • Enables bluetooth service"
            echo "  • Optional: blueman GUI"
            ;;
        "Setup Printer")
            echo "Installs CUPS and printer drivers."
            echo
            echo "  • HP: hplip"
            echo "  • Epson: epson-inkjet-printer-escpr"
            echo "  • Enables CUPS service"
            ;;
        "Setup yay (AUR helper)")
            echo "Builds and installs yay from AUR."
            echo
            echo "  • Arch Linux only"
            echo "  • Requires non-root user"
            ;;
        "Setup paru (AUR helper)")
            echo "Builds and installs paru from AUR."
            echo
            echo "  • Arch Linux only"
            echo "  • Requires non-root user"
            ;;
        "DSXSwap")
            echo "Configure swap space on your system."
            echo
            echo "  • Create and manage swap files"
            echo "  • Adjust swappiness settings"
            echo "  • Monitor swap usage"
            ;;
        "DSXSecurity")
            echo "Firewall, SSH hardening, and security checks in one module."
            echo
            echo "  • nftables firewall with Home / Public / Gaming profiles"
            echo "  • SSH hardening: change port, disable root/password login, restore backup"
            echo "  • Security updates, package integrity, and login activity checks"
            ;;
        "Sober Optimization")
            echo "Configura otimizações para o Sober."
            echo
            echo "  • Ajusta modo gráfico para performance"
            echo "  • Opcional: override FRM, Discord RPC, GameMode, gamepad"
            echo "  • Salva o arquivo JSON em ~/.var/app/org.vinegarhq.Sober/config/sober/config.json"
            ;;
        "Setup Drivers")
            echo "Detects your GPU vendor and installs the right driver stack."
            echo
            echo "  • Auto-detects GPU via lspci (NVIDIA / AMD / Intel)"
            echo "  • NVIDIA: delegates to dedicated module (series pick, DKMS/akmod, Secure Boot warning)"
            echo "  • AMD: mesa, Vulkan (RADV), VA-API/VDPAU, 32-bit libs"
            echo "  • Intel: mesa, Vulkan, VA-API media driver"
            ;;
        "DSXHealth")
            echo "Keep your system clean, light, and healthy with simple maintenance tasks."
            echo
            echo "  • Update the system"
            echo "  • Clear old package cache"
            echo "  • Remove unused programs"
            echo "  • Clean temporary files"
            echo "  • Empty trash"
            echo "  • Check what is using space"
            echo "  • Check for system problems"
            echo
            echo "  Multi-select with TAB."
            ;;
        "Setup Fastfetch")
            echo "Install and configure Fastfetch."
            echo
            echo "  • Installs fastfetch (.deb on Debian/Ubuntu)"
            echo "  • Deploys a default config (backs up existing)"
            echo "  • Optional: run on every new shell"
            ;;
        "Setup Multimedia")
            echo "Install and configure Multimedia dependencies."
            echo
            echo "  • Installs codecs (ffmpeg, gstreamer plugins, libdvdcss)"
            echo "  • Installs media players (vlc, mpv)"
            echo "  • Configures hardware acceleration (VAAPI/VDPAU) where available"
            ;;
        "Exit")
            echo "Exit dsxtool."
            ;;
    esac
}

get_preview "$1"
