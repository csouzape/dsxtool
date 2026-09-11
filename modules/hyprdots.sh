#!/usr/bin/env bash
# This script set up the hyprdots configuration for hyprland, the link is; https://github.com/csouzape/hyprdots

check_dependencies() {
    clear
	if command -v git &>/dev/null; then
		log_info "git already installed. ($(command -v git))."
		return 0
	fi

	log_warn "git not found. Installing..."
	if pkg_install git; then
		log_info "git installed successfully."
	else
		log_error "Failed to install git."
		return 1
	fi
}

clone_hyprdots() {
    clear
	check_dependencies || return 1

    local repo_url="https://github.com/csouzape/hyprdots.git"
	local clone_dir
	local install_script

	clone_dir=$(mktemp -d) || return 1
	install_script="$clone_dir/install.sh"

	log_info "Cloning hyprdots..."
	if ! git clone --depth 1 "$repo_url" "$clone_dir"; then
		log_error "Failed to clone $repo_url."
		rm -rf "$clone_dir"
		return 1
	fi

	if [[ ! -f "$install_script" ]]; then
		log_error "install.sh not found in $repo_url."
		rm -rf "$clone_dir"
		return 1
	fi

	chmod +x "$install_script"
	log_info "Running hyprdots install.sh..."
	if [[ -e /dev/tty ]]; then
		bash "$install_script" </dev/tty
	else
		bash "$install_script"
	fi
	local status=$?

	rm -rf "$clone_dir"
	if [[ $status -ne 0 ]]; then
		log_error "hyprdots installation failed."
		return "$status"
	fi

	log_success "hyprdots installation completed successfully."
}

main(){
    check_dependencies || return 1
    clone_hyprdots || return 1
}