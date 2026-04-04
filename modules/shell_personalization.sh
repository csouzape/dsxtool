#!/usr/bin/env bash
set -euo pipefail

install_zsh() {
    log_info "Installing zsh..."
    pkg_install zsh || die "Failed to install zsh."

    log_info "Installing oh-my-zsh..."
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        log_warn "oh-my-zsh already installed. Skipping."
    else
        local tmp_script
        tmp_script=$(mktemp)
        curl -fsSL "https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh" -o "$tmp_script" \
            || die "Failed to download oh-my-zsh installer."
        chmod +x "$tmp_script"
        RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh "$tmp_script" --unattended \
            || { rm -f "$tmp_script"; die "Failed to install oh-my-zsh."; }
        rm -f "$tmp_script"
    fi

    log_info "Installing zsh plugins..."
    local zsh_custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

    if [[ ! -d "$zsh_custom/plugins/zsh-autosuggestions" ]]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions \
            "$zsh_custom/plugins/zsh-autosuggestions" \
            || die "Failed to clone zsh-autosuggestions."
    else
        log_warn "zsh-autosuggestions already installed. Skipping."
    fi

    if [[ ! -d "$zsh_custom/plugins/zsh-syntax-highlighting" ]]; then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting \
            "$zsh_custom/plugins/zsh-syntax-highlighting" \
            || die "Failed to clone zsh-syntax-highlighting."
    else
        log_warn "zsh-syntax-highlighting already installed. Skipping."
    fi

    log_info "Enabling plugins in ~/.zshrc..."
    [[ -f "$HOME/.zshrc" ]] && cp "$HOME/.zshrc" "$HOME/.zshrc.bak"
    if grep -q "^plugins=" "$HOME/.zshrc" 2>/dev/null; then
        sed -i 's/^plugins=(.*/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' "$HOME/.zshrc"
    else
        echo 'plugins=(git zsh-autosuggestions zsh-syntax-highlighting)' >> "$HOME/.zshrc"
    fi

    log_info "zsh installed successfully."
}

install_fish() {
    log_info "Installing fish..."
    pkg_install fish || die "Failed to install fish."

    log_info "Installing fisher (plugin manager)..."
    if ! fish -c "type fisher" &>/dev/null; then
        local fisher_script
        fisher_script=$(mktemp)
        curl -fsSL "https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish" -o "$fisher_script" \
            || die "Failed to download fisher installer."
        fish -c "source '$fisher_script'; fisher install jorgebucaran/fisher" \
            || { rm -f "$fisher_script"; die "Failed to install fisher."; }
        rm -f "$fisher_script"
    else
        log_warn "fisher already installed. Skipping."
    fi

    log_info "Installing fish plugins via fisher..."
    fish -c "fisher install jethrokuan/z"            || log_warn "Failed to install jethrokuan/z."
    fish -c "fisher install PatrickF1/fzf.fish"      || log_warn "Failed to install fzf.fish."
    fish -c "fisher install jorgebucaran/autopair.fish" || log_warn "Failed to install autopair.fish."

    log_info "fish installed successfully."
}

set_default_shell() {
    local shell_path="$1"
    local target_user="${SUDO_USER:-$USER}"

    if ! grep -q "^${shell_path}$" /etc/shells 2>/dev/null; then
        log_warn "$shell_path not found in /etc/shells. Adding..."
        echo "$shell_path" | sudo tee -a /etc/shells >/dev/null
    fi

    log_info "Setting $shell_path as default shell for $target_user..."
    sudo chsh -s "$shell_path" "$target_user" \
        || die "Failed to set default shell. Try running: chsh -s $shell_path"

    log_info "Default shell set to $shell_path. Re-login to apply."
}

setup_shell() {
    local choice
    choice=$(printf '%s\n' "zsh" "fish" "Cancel" \
        | fzf \
              --prompt="Shell > " \
              --header="Select a shell to install" \
              --height=8 \
              --layout=reverse \
              --border=rounded \
              --pointer="▶" \
              --color="bg:#121212,bg+:#1e1e1e,fg:#d1d1d1,fg+:#ffffff,hl:#89b4fa,prompt:#cba6f7,pointer:#f38ba8,header:#f9e2af,border:#2a2a2a" \
              --no-info)

    case "$choice" in
        zsh)
            install_zsh
            set_default_shell "$(command -v zsh)"
            ;;
        fish)
            install_fish
            set_default_shell "$(command -v fish)"
            ;;
        "Cancel"|"")
            log_warn "Shell setup cancelled."
            return 0
            ;;
    esac
}