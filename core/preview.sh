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
        "DSXConfig")
            echo "Backup and restore your Linux setup."
            echo
            echo "  • Export packages, AUR, Flatpak"
            echo "  • Restore on any machine"
            echo "  • Cross-distro support"
            echo "  • Part of the DSX ecosystem"
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
        "DSXSWAP (BETA)")
            echo "Configure swap space on your system."
            echo
            echo "  • Create and manage swap files"
            echo "  • Adjust swappiness settings"
            echo "  • Monitor swap usage"
            ;;
        "Setup NVIDIA Drivers")
            echo "Install proprietary NVIDIA drivers."
            echo
            echo "  • Auto-detects GPU via lspci"
            echo "  • Picks driver series (current / 470xx / 390xx)"
            echo "  • Installs 32-bit libs + DKMS/akmod"
            echo "  • Enables DRM modeset (Wayland-ready)"
            echo "  • Warns on Secure Boot"
            ;;
        "System Maintenance")
            echo "Clean up and tune your system."
            echo
            echo "  • Update system packages"
            echo "  • Clean package manager cache"
            echo "  • Remove orphan packages"
            echo "  • Vacuum systemd journal logs"
            echo "  • Clean user cache (~/.cache)"
            echo "  • TRIM SSD (fstrim)"
            echo "  • Remove unused Flatpak runtimes"
            echo "  • Check failed services"
            echo
            echo "  Multi-select with TAB."
            ;;
        "Exit")
            echo "Exit dsxtool."
            ;;
    esac
}

get_preview "$1"