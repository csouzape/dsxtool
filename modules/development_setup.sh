#!/usr/bin/env bash
set -uo pipefail

_fzf_menu() {
    local tmp_in tmp_out
    tmp_in=$(mktemp)
    tmp_out=$(mktemp)
    cat > "$tmp_in"
    fzf "$@" < "$tmp_in" > "$tmp_out" || true
    cat "$tmp_out"
    rm -f "$tmp_in" "$tmp_out"
}


_check_yay() {
    if ! command -v yay &>/dev/null; then
        die "yay is not installed. Please run 'Setup yay' first."
    fi
}

_install_jetbrains_flatpak() {
    local name="$1" flatpak_id="$2"
    flatpak install -y flathub "$flatpak_id" \
        && log_info "$name installed successfully." \
        || die "Failed to install $name."
}

_install_jetbrains_aur() {
    local name="$1" aur_pkg="$2"
    _check_not_root "$name"
    _check_yay
    sudo -u "${SUDO_USER:-$USER}" yay -S --noconfirm "$aur_pkg" \
        && log_info "$name installed successfully." \
        || die "Failed to install $name."
}

_install_jetbrains() {
    local name="$1" aur_pkg="$2" flatpak_id="$3"
    log_info "Installing $name..."
    if [[ "$DISTRO" == "arch" ]]; then
        _install_jetbrains_aur "$name" "$aur_pkg"
    else
        _install_jetbrains_flatpak "$name" "$flatpak_id"
    fi
}


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
        "NVM")
            log_info "Installing NVM (Node Version Manager)..."
            curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash \
                && log_info "NVM installed. Restart your shell to use it." \
                || die "Failed to install NVM."
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
                    | _fzf_menu \
                        --prompt="VS Code install method > " \
                        --height=5 --layout=reverse --border=rounded --no-info \
                        --color="bg:#121212,bg+:#1e1e1e,fg:#d1d1d1,fg+:#ffffff,prompt:#cba6f7,pointer:#f38ba8,border:#2a2a2a")
                case "$method" in
                    yay)
                        _check_yay
                        sudo -u "${SUDO_USER:-$USER}" yay -S --noconfirm visual-studio-code-bin \
                            && log_info "VS Code installed successfully." \
                            || die "Failed to install VS Code."
                        ;;
                    flatpak) flatpak install -y flathub com.visualstudio.code ;;
                    *)       log_warn "No method selected."; return 0 ;;
                esac
            else
                flatpak install -y flathub com.visualstudio.code
            fi
            log_info "VS Code installed successfully."
            ;;
        "VSCodium")
            log_info "Installing VSCodium..."
            if [[ "$DISTRO" == "arch" ]]; then
                _check_yay
                sudo -u "${SUDO_USER:-$USER}" yay -S --noconfirm vscodium-bin \
                    && log_info "VSCodium installed successfully." \
                    || die "Failed to install VSCodium."
            else
                flatpak install -y flathub com.vscodium.codium \
                    && log_info "VSCodium installed successfully." \
                    || die "Failed to install VSCodium."
            fi
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
                _check_yay
                sudo -u "${SUDO_USER:-$USER}" yay -S --noconfirm cursor-bin \
                    && log_info "Cursor installed successfully." \
                    || die "Failed to install Cursor."
            else
                flatpak install -y flathub com.cursor.Cursor \
                    && log_info "Cursor installed successfully." \
                    || die "Failed to install Cursor."
            fi
            ;;
        "Claude Code")
            log_info "Installing Claude Code..."
            if ! command -v npm &>/dev/null; then
                log_warn "npm not found. Installing Node.js first..."
                install_lang "Node.js"
            fi
            sudo npm install -g @anthropic-ai/claude-code \
                && log_info "Claude Code installed successfully." \
                || die "Failed to install Claude Code."
            ;;
        "Arduino IDE")
            log_info "Installing Arduino IDE..."
            case "$DISTRO" in
                arch)
                    _check_not_root "Arduino IDE"
                    _check_yay
                    sudo -u "${SUDO_USER:-$USER}" yay -S --noconfirm arduino-ide-bin \
                        && log_info "Arduino IDE installed successfully." \
                        || die "Failed to install Arduino IDE."
                    ;;
                debian|fedora)
                    flatpak install -y flathub cc.arduino.arduinoide \
                        && log_info "Arduino IDE installed successfully." \
                        || die "Failed to install Arduino IDE."
                    ;;
            esac
            ;;

        
        "JetBrains Toolbox")
            log_info "Installing JetBrains Toolbox..."
            if [[ "$DISTRO" == "arch" ]]; then
                _install_jetbrains_aur "JetBrains Toolbox" "jetbrains-toolbox"
            else
                local tmp_dir
                tmp_dir=$(mktemp -d)
                local url
                url=$(curl -s "https://data.services.jetbrains.com/products/releases?code=TBA&latest=true&type=release" \
                    | grep -o '"linux":{[^}]*}' \
                    | grep -o '"link":"[^"]*"' \
                    | head -1 \
                    | sed 's/"link":"//;s/"//')
                [[ -z "$url" ]] && die "Failed to get JetBrains Toolbox download URL."
                curl -L "$url" -o "$tmp_dir/toolbox.tar.gz" \
                    || die "Failed to download JetBrains Toolbox."
                tar -xzf "$tmp_dir/toolbox.tar.gz" -C "$tmp_dir"
                local binary
                binary=$(find "$tmp_dir" -name "jetbrains-toolbox" -type f | head -1)
                sudo install "$binary" /usr/local/bin/jetbrains-toolbox \
                    && log_info "JetBrains Toolbox installed. Run: jetbrains-toolbox" \
                    || die "Failed to install JetBrains Toolbox."
                rm -rf "$tmp_dir"
            fi
            ;;
        "IntelliJ IDEA")
            _install_jetbrains "IntelliJ IDEA" \
                "intellij-idea-community-edition" \
                "com.jetbrains.IntelliJ-IDEA-Community"
            ;;
        "PyCharm")
            _install_jetbrains "PyCharm" \
                "pycharm-community-edition" \
                "com.jetbrains.PyCharm-Community"
            ;;
        "WebStorm")
            _install_jetbrains "WebStorm" \
                "webstorm" \
                "com.jetbrains.WebStorm"
            ;;
        "PhpStorm")
            _install_jetbrains "PhpStorm" \
                "phpstorm" \
                "com.jetbrains.PhpStorm"
            ;;
        "GoLand")
            _install_jetbrains "GoLand" \
                "goland" \
                "com.jetbrains.GoLand"
            ;;
        "CLion")
            _install_jetbrains "CLion" \
                "clion" \
                "com.jetbrains.CLion"
            ;;
        "RustRover")
            _install_jetbrains "RustRover" \
                "rustrover" \
                "com.jetbrains.RustRover"
            ;;
        "DataGrip")
            _install_jetbrains "DataGrip" \
                "datagrip" \
                "com.jetbrains.DataGrip"
            ;;
        "Rider")
            _install_jetbrains "Rider" \
                "rider" \
                "com.jetbrains.Rider"
            ;;
        "RubyMine")
            _install_jetbrains "RubyMine" \
                "rubymine" \
                "com.jetbrains.RubyMine"
            ;;
        "DataSpell")
            _install_jetbrains "DataSpell" \
                "dataspell" \
                "com.jetbrains.DataSpell"
            ;;
        "Oracle SQL Developer")
            log_info "Installing Oracle SQL Developer..."
            if ! command -v java &>/dev/null; then
                log_warn "Java not found. Installing OpenJDK 17 first..."
                install_lang "Java (OpenJDK 17)"
            fi
            pkg_install unzip || die "Failed to install unzip."
            local tmp_dir url
            tmp_dir=$(mktemp -d)
            url="https://download.oracle.com/otn/java/sqldeveloper/sqldeveloper-23.3.1.345.2114-no-jre.zip"
            curl -L "$url" -o "$tmp_dir/sqldeveloper.zip" || die "Failed to download Oracle SQL Developer."
            sudo unzip "$tmp_dir/sqldeveloper.zip" -d /opt/ || die "Failed to extract."
            sudo ln -sf /opt/sqldeveloper/sqldeveloper.sh /usr/local/bin/sqldeveloper || die "Failed to create symlink."
            rm -rf "$tmp_dir"
            log_info "Oracle SQL Developer installed. Run: sqldeveloper"
            ;;
    esac
}

install_devtool() {
    case "$1" in
        "Postman")
            flatpak install -y flathub com.getpostman.Postman \
                && log_info "Postman installed successfully." \
                || die "Failed to install Postman."
            ;;
        "DBeaver")
            log_info "Installing DBeaver..."
            case "$DISTRO" in
                arch)
                    _check_yay
                    sudo -u "${SUDO_USER:-$USER}" yay -S --noconfirm dbeaver-ce \
                        && log_info "DBeaver installed successfully." \
                        || die "Failed to install DBeaver."
                    ;;
                debian)
                    curl -fsSL https://dbeaver.io/debs/dbeaver.gpg.key \
                        | sudo gpg --dearmor -o /etc/apt/keyrings/dbeaver.gpg \
                        || die "Failed to import DBeaver GPG key."
                    echo "deb [signed-by=/etc/apt/keyrings/dbeaver.gpg] https://dbeaver.io/debs/dbeaver-ce /" \
                        | sudo tee /etc/apt/sources.list.d/dbeaver.list
                    sudo apt update -y
                    pkg_install dbeaver-ce \
                        && log_info "DBeaver installed successfully." \
                        || die "Failed to install DBeaver."
                    ;;
                fedora)
                    sudo rpm --import https://dbeaver.io/debs/dbeaver.gpg.key \
                        || die "Failed to import DBeaver GPG key."
                    sudo dnf config-manager --add-repo \
                        https://dbeaver.io/rpm/dbeaver-ce/x86_64/ \
                        || die "Failed to add DBeaver repo."
                    pkg_install dbeaver-ce \
                        && log_info "DBeaver installed successfully." \
                        || die "Failed to install DBeaver."
                    ;;
            esac
            ;;
        "Insomnia")
            flatpak install -y flathub rest.insomnia.Insomnia \
                && log_info "Insomnia installed successfully." \
                || die "Failed to install Insomnia."
            ;;
        "PostgreSQL")
            log_info "Installing PostgreSQL server..."
            case "$DISTRO" in
                arch)
                    pkg_install postgresql || die "Failed to install PostgreSQL."
                    if [[ ! -d /var/lib/postgres/data/base ]]; then
                        sudo -u postgres initdb -D /var/lib/postgres/data \
                            || die "Failed to initialize PostgreSQL."
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
                || log_warn "Failed to enable PostgreSQL."
            log_info "PostgreSQL installed successfully."
            ;;
        "PostgreSQL Client")
            log_info "Installing PostgreSQL client..."
            case "$DISTRO" in
                arch)   pkg_install postgresql-libs || die "Failed." ;;
                debian) pkg_install postgresql-client || die "Failed." ;;
                fedora) pkg_install postgresql || die "Failed." ;;
            esac
            log_info "PostgreSQL client installed successfully."
            ;;
        "MySQL Client")
            log_info "Installing MySQL client..."
            case "$DISTRO" in
                arch)   pkg_install mariadb-clients || die "Failed." ;;
                debian) pkg_install default-mysql-client || die "Failed." ;;
                fedora) pkg_install mariadb || die "Failed." ;;
            esac
            log_info "MySQL client installed successfully."
            ;;
        "Redis")
            log_info "Installing Redis server..."
            case "$DISTRO" in
                arch)   pkg_install redis ;;
                debian) pkg_install redis-server ;;
                fedora) pkg_install redis ;;
            esac
            sudo systemctl enable --now redis \
                || log_warn "Failed to enable Redis."
            log_info "Redis installed successfully."
            ;;
        "Redis Tools")
            log_info "Installing Redis client tools..."
            case "$DISTRO" in
                arch)   pkg_install redis || die "Failed." ;;
                debian) pkg_install redis-tools || die "Failed." ;;
                fedora) pkg_install redis || die "Failed." ;;
            esac
            log_info "Redis tools installed successfully."
            ;;
        "SQLite")
            log_info "Installing SQLite..."
            case "$DISTRO" in
                arch)   pkg_install sqlite || die "Failed." ;;
                debian) pkg_install sqlite3 || die "Failed." ;;
                fedora) pkg_install sqlite || die "Failed." ;;
            esac
            log_info "SQLite installed successfully."
            ;;
        "HTTPie")
            log_info "Installing HTTPie..."
            pkg_install httpie || die "Failed to install HTTPie."
            log_info "HTTPie installed successfully."
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
        "GCC")
            log_info "Installing GCC..."
            case "$DISTRO" in
                arch)   pkg_install gcc || die "Failed." ;;
                debian) pkg_install build-essential || die "Failed." ;;
                fedora) pkg_install gcc || die "Failed." ;;
            esac
            log_info "GCC installed successfully."
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
        "Podman")
            pkg_install podman || die "Failed to install Podman."
            flatpak install -y flathub io.podman_desktop.PodmanDesktop \
                && log_info "Podman installed successfully." \
                || die "Failed to install Podman Desktop."
            ;;
        "Kubectl")
            log_info "Installing kubectl..."
            case "$DISTRO" in
                arch)   pkg_install kubectl || die "Failed." ;;
                debian)
                    curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key \
                        | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
                    echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
                        https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /" \
                        | sudo tee /etc/apt/sources.list.d/kubernetes.list
                    sudo apt update -y
                    pkg_install kubectl || die "Failed."
                    ;;
                fedora) pkg_install kubectl || die "Failed." ;;
            esac
            log_info "kubectl installed successfully."
            ;;
        "Minikube")
            log_info "Installing Minikube..."
            case "$DISTRO" in
                arch)   pkg_install minikube || die "Failed." ;;
                debian)
                    curl -fsSL https://storage.googleapis.com/minikube/releases/latest/minikube_latest_amd64.deb \
                        -o /tmp/minikube.deb
                    sudo dpkg -i /tmp/minikube.deb || die "Failed."
                    rm -f /tmp/minikube.deb
                    ;;
                fedora)
                    curl -fsSL https://storage.googleapis.com/minikube/releases/latest/minikube-latest.x86_64.rpm \
                        -o /tmp/minikube.rpm
                    sudo rpm -Uvh /tmp/minikube.rpm || die "Failed."
                    rm -f /tmp/minikube.rpm
                    ;;
            esac
            log_info "Minikube installed successfully."
            ;;
        "Terraform")
            log_info "Installing Terraform..."
            case "$DISTRO" in
                arch)   pkg_install terraform || die "Failed." ;;
                debian)
                    wget -O - https://apt.releases.hashicorp.com/gpg \
                        | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
                    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
                        https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
                        | sudo tee /etc/apt/sources.list.d/hashicorp.list
                    sudo apt update -y
                    pkg_install terraform || die "Failed."
                    ;;
                fedora)
                    sudo dnf config-manager --add-repo \
                        https://rpm.releases.hashicorp.com/fedora/hashicorp.repo
                    pkg_install terraform || die "Failed."
                    ;;
            esac
            log_info "Terraform installed successfully."
            ;;
    esac
}

install_cli_tool() {
    case "$1" in
        "bat")      pkg_install bat      || die "Failed to install bat." ;;
        "ripgrep")  pkg_install ripgrep  || die "Failed to install ripgrep." ;;
        "tmux")     pkg_install tmux     || die "Failed to install tmux." ;;
        "jq")       pkg_install jq       || die "Failed to install jq." ;;
        "fzf")      pkg_install fzf      || die "Failed to install fzf." ;;
        "fd")
            case "$DISTRO" in
                arch)          pkg_install fd       || die "Failed." ;;
                debian|fedora) pkg_install fd-find  || die "Failed." ;;
            esac
            ;;
        "git-lfs")
            pkg_install git-lfs || die "Failed to install git-lfs."
            git lfs install
            ;;
        "GitHub CLI (gh)")
            case "$DISTRO" in
                arch)   pkg_install github-cli || die "Failed." ;;
                debian)
                    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
                        | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
                    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] \
                        https://cli.github.com/packages stable main" \
                        | sudo tee /etc/apt/sources.list.d/github-cli.list
                    sudo apt update -y
                    pkg_install gh || die "Failed."
                    ;;
                fedora) pkg_install gh || die "Failed." ;;
            esac
            ;;
        "lazygit")
            case "$DISTRO" in
                arch) pkg_install lazygit || die "Failed." ;;
                debian|fedora)
                    local version
                    version=$(curl -s https://api.github.com/repos/jesseduffield/lazygit/releases/latest \
                        | grep '"tag_name"' | sed 's/.*"v\([^"]*\)".*/\1/')
                    curl -Lo /tmp/lazygit.tar.gz \
                        "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${version}_Linux_x86_64.tar.gz"
                    tar -xf /tmp/lazygit.tar.gz -C /tmp lazygit
                    sudo install /tmp/lazygit /usr/local/bin
                    rm -f /tmp/lazygit.tar.gz /tmp/lazygit
                    ;;
            esac
            ;;
    esac
    log_info "$1 installed successfully."
}

_FZF_COLORS="bg:#121212,bg+:#1e1e1e,fg:#d1d1d1,fg+:#ffffff,hl:#89b4fa,prompt:#cba6f7,pointer:#f38ba8,marker:#a6e3a1,header:#f9e2af,border:#2a2a2a"

menu_languages() {
    local selections
    selections=$(printf '%s\n' \
        "Python" "C++" "Rust" "Go" "Node.js" "NVM" \
        "Java (OpenJDK 17)" "Yarn" "PNPM" \
        | _fzf_menu -m \
              --prompt="Languages > " \
              --header="[TAB] Select  [ENTER] Install  [ESC] Back" \
              --height=15 --layout=reverse --border=rounded --pointer="▶" \
              --color="$_FZF_COLORS" --no-info)

    [[ -z "$selections" ]] && { log_warn "No language selected."; return 0; }
    while read -r lang; do [[ -z "$lang" ]] && continue; install_lang "$lang"; done <<< "$selections"
}

menu_ides() {
    local selections
    selections=$(printf '%s\n' \
        "VS Code" "VSCodium" "Zed" "NVIM (LazyVim)" "Kate" "Cursor" "Claude Code" \
        "Arduino IDE" \
        "── JetBrains ──" \
        "JetBrains Toolbox" \
        "IntelliJ IDEA" "PyCharm" "WebStorm" "PhpStorm" \
        "GoLand" "CLion" "RustRover" "DataGrip" "Oracle SQL Developer" \
        "Rider" "RubyMine" "DataSpell" \
        | _fzf_menu -m \
              --prompt="IDEs > " \
              --header="[TAB] Select  [ENTER] Install  [ESC] Back" \
              --height=22 --layout=reverse --border=rounded --pointer="▶" \
              --color="$_FZF_COLORS" --no-info)

    [[ -z "$selections" ]] && { log_warn "No IDE selected."; return 0; }
    while read -r ide; do
        [[ -z "$ide" ]] && continue
        [[ "$ide" == "── JetBrains ──" ]] && continue
        install_ide "$ide"
    done <<< "$selections"
}

menu_devtools() {
    local selections
    selections=$(printf '%s\n' \
        "Postman" "DBeaver" "Insomnia" \
        "PostgreSQL" "PostgreSQL Client" "MySQL Client" \
        "Redis" "Redis Tools" "SQLite" "HTTPie" \
        "Build Tools" "GCC" \
        "Docker" "Podman" "Kubectl" "Minikube" "Terraform" \
        | _fzf_menu -m \
              --prompt="Dev Tools > " \
              --header="[TAB] Select  [ENTER] Install  [ESC] Back" \
              --height=18 --layout=reverse --border=rounded --pointer="▶" \
              --color="$_FZF_COLORS" --no-info)

    [[ -z "$selections" ]] && { log_warn "No tool selected."; return 0; }
    while read -r tool; do [[ -z "$tool" ]] && continue; install_devtool "$tool"; done <<< "$selections"
}

menu_cli_tools() {
    local selections
    selections=$(printf '%s\n' \
        "bat" "ripgrep" "fd" \
        "git-lfs" "GitHub CLI (gh)" "lazygit" \
        "tmux" "jq" "fzf" \
        | _fzf_menu -m \
              --prompt="CLI Tools > " \
              --header="[TAB] Select  [ENTER] Install  [ESC] Back" \
              --height=14 --layout=reverse --border=rounded --pointer="▶" \
              --color="$_FZF_COLORS" --no-info)

    [[ -z "$selections" ]] && { log_warn "No tool selected."; return 0; }
    while read -r tool; do [[ -z "$tool" ]] && continue; install_cli_tool "$tool"; done <<< "$selections"
}

setup_development() {
    while true; do
        local choice
        choice=$(printf '%s\n' \
            "Languages & Runtimes" \
            "IDEs & Editors" \
            "Dev Tools" \
            "CLI Tools" \
            "Exit" \
            | _fzf_menu \
              --prompt="Dev Setup > " \
              --header="DEVELOPMENT SETUP  │  [ENTER] select   [ESC] back" \
              --height=10 --layout=reverse --border=rounded --pointer="▶" \
              --color="$_FZF_COLORS" --no-info)

        case "$choice" in
            "Languages & Runtimes") menu_languages ;;
            "IDEs & Editors")       menu_ides ;;
            "Dev Tools")            menu_devtools ;;
            "CLI Tools")            menu_cli_tools ;;
            "Exit"|"")              return 0 ;;
        esac
    done
}