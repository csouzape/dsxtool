#!/usr/bin/env bash
set -euo pipefail

install_lang() {
    case "$1" in
        "Python")
            log_info "Installing Python..."
            case "$DISTRO" in
                arch)   pkg_install python python-pip python-virtualenv ;;
                debian) pkg_install python3 python3-pip python3-venv ;;
                fedora) pkg_install python3 python3-pip python3-virtualenv ;;
            esac
            log_info "Python installed successfully."
            ;;
        "C++")
            log_info "Installing C++ compilers and tools..."
            case "$DISTRO" in
                arch)   pkg_install base-devel cmake clang ;;
                debian) pkg_install build-essential cmake clang ;;
                fedora) pkg_install gcc gcc-c++ cmake clang ;;
            esac
            log_info "C++ installed successfully."
            ;;
        "Rust")
            log_info "Installing Rust via rustup..."
            curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y \
                && log_info "Rust installed successfully." \
                || die "Failed to install Rust."
            ;;
        "Go")
            log_info "Installing Go..."
            case "$DISTRO" in
                arch)   pkg_install go ;;
                debian) pkg_install golang-go ;;
                fedora) pkg_install golang ;;
            esac
            log_info "Go installed successfully."
            ;;
        "Node.js")
            log_info "Installing Node.js..."
            local missing=()
            pkg_exists nodejs || missing+=(nodejs)
            pkg_exists npm    || missing+=(npm)
            if [[ ${#missing[@]} -eq 0 ]]; then
                log_warn "Node.js and npm are already installed. Skipping."
                return 0
            fi
            pkg_install "${missing[@]}" \
                && log_info "Node.js installed successfully." \
                || die "Failed to install Node.js."
            ;;
        "Java (OpenJDK 17)")
            log_info "Installing OpenJDK 17 + Maven + Gradle..."
            case "$DISTRO" in
                arch)   pkg_install jdk17-openjdk maven gradle ;;
                debian) pkg_install openjdk-17-jdk maven gradle ;;
                fedora) pkg_install java-17-openjdk maven gradle ;;
            esac
            log_info "Java installed successfully."
            ;;
        "Yarn")
            log_info "Installing Yarn..."
            case "$DISTRO" in
                arch)   pkg_install yarn ;;
                debian) pkg_install yarn ;;
                fedora) pkg_install yarnpkg ;;
            esac
            log_info "Yarn installed successfully."
            ;;
        "PNPM")
            log_info "Installing PNPM..."
            curl -fsSL https://get.pnpm.io/install.sh | sh - \
                && log_info "PNPM installed successfully." \
                || die "Failed to install PNPM."
            ;;
    esac
}



install_ide() {
    case "$1" in
        "VS Code")
            log_info "Installing VS Code..."
            if [[ "$DISTRO" == "arch" ]]; then
                local method
                method=$(printf "yay\nflatpak" \
                    | fzf --prompt="VS Code install method > " \
                          --height=5 --layout=reverse --border=rounded --no-info \
                    || true)
                case "$method" in
                    yay)
                        if ! command -v yay &>/dev/null; then
                            die "yay is not installed. Please run 'Setup yay' first."
                        fi
                        yay -S --noconfirm visual-studio-code-bin
                        ;;
                    flatpak) flatpak install -y flathub com.visualstudio.code ;;
                    *)       log_warn "No method selected."; return 0 ;;
                esac
            else
                flatpak install -y flathub com.visualstudio.code
            fi
            log_info "VS Code installed successfully."
            ;;
        "Zed")
            log_info "Installing Zed..."
            curl --proto '=https' --tlsv1.2 -sSf https://zed.dev/install.sh | sh \
                && log_info "Zed installed successfully." \
                || die "Failed to install Zed."
            ;;
        "NVIM (LazyVim)")
            log_info "Installing Neovim + LazyVim..."
            pkg_install neovim git make unzip \
                || die "Failed to install Neovim dependencies."
            if [[ -d ~/.config/nvim ]]; then
                log_warn "~/.config/nvim already exists. Skipping clone."
            else
                git clone https://github.com/LazyVim/starter ~/.config/nvim \
                    || die "Failed to clone LazyVim."
            fi
            log_info "Neovim + LazyVim installed successfully."
            ;;
        "Kate")
            log_info "Installing Kate..."
            pkg_install kate \
                && log_info "Kate installed successfully." \
                || die "Failed to install Kate."
            ;;
        "Cursor")
            log_info "Installing Cursor..."
            if [[ "$DISTRO" == "arch" ]]; then
                if ! command -v yay &>/dev/null; then
                    die "yay is not installed. Please run 'Setup yay' first."
                fi
                yay -S --noconfirm cursor-bin \
                    && log_info "Cursor installed successfully." \
                    || die "Failed to install Cursor."
            else
                log_info "Installing Cursor via Flatpak..."
                flatpak install -y flathub com.cursor.Cursor \
                    && log_info "Cursor installed successfully." \
                    || die "Failed to install Cursor."
            fi
            ;;
        "Claude Code")
            log_info "Installing Claude Code..."
            if [[ "$DISTRO" == "arch" ]]; then
                if ! command -v yay &>/dev/null; then
                    die "yay is not installed. Please run 'Setup yay' first."
                fi
                yay -S --noconfirm claude-code-bin \
                    && log_info "Claude Code installed successfully." \
                    || die "Failed to install Claude Code."
            else
                log_info "Installing Claude Code via official installer..."
                curl -fsSL https://claude.ai/install.sh | bash \
                    && log_info "Claude Code installed successfully." \
                    || die "Failed to install Claude Code."
            fi
            ;;
        "VScodium") 
            log_info "Installing VScodium..."
            if [[ "$DISTRO" != "arch" ]]; then
                if ! command -v yay &>/dev/null; then 
                    die "yay is not installed.|| Please run 'Setup yay' first."
                fi 
                yay -S --noconfirm vscodium \
                    && log_info "vscodium installed successfully." \
                    || die "Failed to install vscodium."
            else
                log_info "Installing VScodium via flatpka..." 
                flatpak install -y flathub com.vscodium.codium
                    && log_info "VScodium intalled successfully." \ 
                    || die "Failed to install VScodium."
            fi
            ;;
        
    esac
}


install_devtool() {
    case "$1" in
        "Postman")
            log_info "Installing Postman via Flatpak..."
            flatpak install -y flathub com.getpostman.Postman \
                && log_info "Postman installed successfully." \
                || die "Failed to install Postman."
            ;;
        "DBeaver")
            log_info "Installing DBeaver via Flatpak..."
            flatpak install -y flathub io.dbeaver.DBeaverCommunity \
                && log_info "DBeaver installed successfully." \
                || die "Failed to install DBeaver."
            ;;
        "PostgreSQL")
            log_info "Installing PostgreSQL..."
            case "$DISTRO" in
                arch)
                    pkg_install postgresql \
                        || die "Failed to install PostgreSQL."
                    if [[ ! -d /var/lib/postgres/data/base ]]; then
                        log_info "Initializing PostgreSQL database cluster..."
                        sudo -u postgres initdb -D /var/lib/postgres/data \
                            || die "Failed to initialize PostgreSQL."
                    else
                        log_warn "PostgreSQL data directory already exists. Skipping initdb."
                    fi
                    ;;
                debian)
                    pkg_install postgresql postgresql-contrib \
                        || die "Failed to install PostgreSQL."
                    ;;
                fedora)
                    pkg_install postgresql-server postgresql-contrib \
                        || die "Failed to install PostgreSQL."
                    sudo postgresql-setup --initdb \
                        || log_warn "PostgreSQL initdb may have already been run."
                    ;;
            esac
            sudo systemctl enable --now postgresql \
                || log_warn "Failed to enable PostgreSQL service."
            log_info "PostgreSQL installed successfully."
            ;;
        "Redis")
            log_info "Installing Redis..."
            case "$DISTRO" in
                arch)   pkg_install redis ;;
                debian) pkg_install redis-server ;;
                fedora) pkg_install redis ;;
            esac
            sudo systemctl enable --now redis \
                || log_warn "Failed to enable Redis service."
            log_info "Redis installed successfully."
            ;;
        "Build Tools")
            log_info "Installing build tools..."
            case "$DISTRO" in
                arch)   pkg_install base-devel ;;
                debian) pkg_install build-essential ca-certificates gnupg lsb-release software-properties-common ;;
                fedora) pkg_install gcc gcc-c++ make ;;
            esac
            log_info "Build tools installed successfully."
            ;;
        "Terraform")
            log_info "Installing Terraform..."
            case "$DISTRO" in
                arch)
                    pkg_install terraform \
                        || die "Failed to install Terraform."
                    ;;
                debian)
                    wget -O - https://apt.releases.hashicorp.com/gpg \
                        | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
                    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
                        https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
                        | sudo tee /etc/apt/sources.list.d/hashicorp.list
                    sudo apt update -y
                    pkg_install terraform \
                        || die "Failed to install Terraform."
                    ;;
                fedora)
                    sudo dnf config-manager --add-repo \
                        https://rpm.releases.hashicorp.com/fedora/hashicorp.repo
                    pkg_install terraform \
                        || die "Failed to install Terraform."
                    ;;
            esac
            log_info "Terraform installed successfully."
            ;;
        "Minikube")
            log_info "Installing Minikube..."
            case "$DISTRO" in
                arch)
                    pkg_install minikube \
                        || die "Failed to install Minikube."
                    ;;
                debian)
                    curl -fsSL https://storage.googleapis.com/minikube/releases/latest/minikube_latest_amd64.deb \
                        -o /tmp/minikube.deb
                    sudo dpkg -i /tmp/minikube.deb \
                        || die "Failed to install Minikube."
                    rm /tmp/minikube.deb
                    ;;
                fedora)
                    curl -fsSL https://storage.googleapis.com/minikube/releases/latest/minikube-latest.x86_64.rpm \
                        -o /tmp/minikube.rpm
                    sudo rpm -Uvh /tmp/minikube.rpm \
                        || die "Failed to install Minikube."
                    rm /tmp/minikube.rpm
                    ;;
            esac
            log_info "Minikube installed successfully."
            ;;
        "Podman")
            log_info "Installing Podman engine..."
            pkg_install podman \
                || die "Failed to install Podman."
            log_info "Installing Podman Desktop via Flatpak..."
            flatpak install -y flathub io.podman_desktop.PodmanDesktop \
                && log_info "Podman installed successfully." \
                || die "Failed to install Podman Desktop."
            ;;
        "Docker")
            log_info "Installing Docker..."
            case "$DISTRO" in
                arch)
                    pkg_install docker docker-compose
                    sudo systemctl enable --now docker
                    sudo usermod -aG docker "${SUDO_USER:-$USER}"
                    ;;
                debian)
                    curl -fsSL https://get.docker.com | sudo sh \
                        || die "Failed to install Docker."
                    sudo usermod -aG docker "${SUDO_USER:-$USER}"
                    ;;
                fedora)
                    sudo dnf config-manager --add-repo \
                        https://download.docker.com/linux/fedora/docker-ce.repo
                    pkg_install docker-ce docker-ce-cli containerd.io \
                        docker-buildx-plugin docker-compose-plugin
                    sudo systemctl enable --now docker
                    sudo usermod -aG docker "${SUDO_USER:-$USER}"
                    ;;
            esac
            log_info "Docker installed. Re-login to use Docker without sudo."
            ;;
        "Kubectl")
            log_info "Installing kubectl..."
            case "$DISTRO" in
                arch)
                    pkg_install kubectl \
                        || die "Failed to install kubectl."
                    ;;
                debian)
                    curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key \
                        | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
                    echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
                        https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /" \
                        | sudo tee /etc/apt/sources.list.d/kubernetes.list
                    sudo apt update -y
                    pkg_install kubectl \
                        || die "Failed to install kubectl."
                    ;;
                fedora)
                    pkg_install kubectl \
                        || die "Failed to install kubectl."
                    ;;
            esac
            log_info "kubectl installed successfully."
            ;;
        "gcc")
            log_info "Installing Gcc.." 
            case "$DISTRO" in 
                arch) 
                    pkg_install gcc \ 
                    || die "Failed to install gcc."
                    ;;
                debian) 
                    pkg_install build-essential \ 
                    || DIE "Failed to install gcc."
                    ;;
                fedora) 
                    pkg_install gcc \ 
                    || die "Failed to install gcc."
                    ;;
            esac 
            log_info "gcc installed successfully."
    esac
}

menu_languages() {
    local selections
    selections=$(printf '%s\n' \
        "Python" "C++" "Rust" "Go" "Node.js" \
        "Java (OpenJDK 17)" "Yarn" "PNPM" \
        | fzf -m \
              --prompt="Languages > " \
              --header="[TAB] Select  [ENTER] Install  [ESC] Back" \
              --height=15 \
              --layout=reverse \
              --border=rounded \
              --pointer="▶" \
              --color='header:#e5c07b,prompt:#61afef,pointer:#e06c75,hl:#98c379' \
              --no-info \
        || true)

    [[ -z "$selections" ]] && { log_warn "No language selected."; return 0; }
    while read -r lang; do
        [[ -z "$lang" ]] && continue
        install_lang "$lang"
    done <<< "$selections"
}

menu_ides() {
    local selections
    selections=$(printf '%s\n' \
        "VS Code" "Zed" "NVIM (LazyVim)" "Kate" "Cursor" "Claude Code" "VScodium" \
        | fzf -m \
              --prompt="IDEs > " \
              --header="[TAB] Select  [ENTER] Install  [ESC] Back" \
              --height=12 \
              --layout=reverse \
              --border=rounded \
              --pointer="▶" \
              --color='header:#e5c07b,prompt:#61afef,pointer:#e06c75,hl:#98c379' \
              --no-info \
        || true)

    [[ -z "$selections" ]] && { log_warn "No IDE selected."; return 0; }
    while read -r ide; do
        [[ -z "$ide" ]] && continue
        install_ide "$ide"
    done <<< "$selections"
}

menu_devtools() {
    local selections
    selections=$(printf '%s\n' \
        "Postman" \
        "DBeaver" \
        "PostgreSQL" \
        "Redis" \
        "Build Tools" \
        "Docker" \
        "Podman" \
        "Kubectl" \
        "Minikube" \
        "Terraform" \
        | fzf -m \
              --prompt="Dev Tools > " \
              --header="[TAB] Select  [ENTER] Install  [ESC] Back" \
              --height=16 \
              --layout=reverse \
              --border=rounded \
              --pointer="▶" \
              --color='header:#e5c07b,prompt:#61afef,pointer:#e06c75,hl:#98c379' \
              --no-info \
        || true)

    [[ -z "$selections" ]] && { log_warn "No tool selected."; return 0; }
    while read -r tool; do
        [[ -z "$tool" ]] && continue
        install_devtool "$tool"
    done <<< "$selections"
}

setup_development() {
    while true; do
        local choice
        choice=$(printf '%s\n' \
            "Languages & Runtimes" \
            "IDEs & Editors" \
            "Dev Tools" \
            "Exit" \
            | fzf --prompt="Dev Setup > " \
                  --header="DEVELOPMENT SETUP" \
                  --height=9 \
                  --layout=reverse \
                  --border=rounded \
                  --pointer="▶" \
                  --color='header:#e5c07b,prompt:#61afef,pointer:#e06c75,hl:#98c379' \
                  --no-info \
            || true)

        case "$choice" in
            "Languages & Runtimes") menu_languages ;;
            "IDEs & Editors")       menu_ides ;;
            "Dev Tools")            menu_devtools ;;
            "Exit"|"")              log_info "Exiting."; return 0 ;;
        esac
    done
}