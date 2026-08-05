#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$BASE_DIR/core/common.sh"
source "$BASE_DIR/core/detect.sh"

detect_distro

if [[ ! -f "$BASE_DIR/core/distros/$DISTRO.sh" ]]; then
	die "Unsupported distro: $DISTRO"
fi

source "$BASE_DIR/core/distros/$DISTRO.sh"

command_exists() {
	command -v "$1" >/dev/null 2>&1
}

gitpath="$HOME/.local/share/mybash"

installDepend() {
	if ! command_exists bash || ! command_exists tar || ! command_exists bat || ! command_exists tree || ! command_exists unzip || ! command_exists fc-list || ! command_exists git; then
		log_info "Installing dependencies..."
		pkg_install bash bash-completion tar bat tree unzip fontconfig git fzf || log_warn "Some packages may have failed to install."
	else
		log_info "All required dependencies already installed."
	fi
}

cloneMyBash() {
	if [ -d "$gitpath" ]; then
		rm -rf "$gitpath"
	fi
	mkdir -p "$HOME/.local/share"

	if git clone --depth 1 https://github.com/csouzape/bashconfig "$gitpath"; then
		log_info "Repository cloned to $gitpath"
		return 0
	fi

	log_warn "Git clone failed; attempting to download key files directly."
	mkdir -p "$gitpath"
	local base_raw="https://raw.githubusercontent.com/csouzape/bashconfig/main"
	for f in .bashrc starship.toml; do
		if curl -fsSL "$base_raw/$f" -o "$gitpath/$f"; then
			log_info "Downloaded $f to $gitpath"
		else
			log_warn "Failed to download $f from $base_raw/$f"
		fi
	done
}

installFont() {
	FONT_NAME="MesloLGS Nerd Font Mono"
	if fc-list :family | grep -iq "$FONT_NAME"; then
		log_info "Font '$FONT_NAME' is installed."
		return
	fi

	log_info "Installing font '$FONT_NAME'..."
	FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.zip"
	FONT_DIR="$HOME/.local/share/fonts"
	TEMP_DIR=$(mktemp -d)
	curl -sSLo "$TEMP_DIR/${FONT_NAME}.zip" "$FONT_URL" || { log_error "Failed to download font."; rm -rf "$TEMP_DIR"; return 1; }
	unzip -q "$TEMP_DIR/${FONT_NAME}.zip" -d "$TEMP_DIR" || { log_error "Failed to unzip font."; rm -rf "$TEMP_DIR"; return 1; }
	mkdir -p "$FONT_DIR/$FONT_NAME"
	mv "$TEMP_DIR"/*.ttf "$FONT_DIR/$FONT_NAME" 2>/dev/null || true
	fc-cache -fv || log_warn "fc-cache failed."
	rm -rf "$TEMP_DIR"
	log_info "Font '$FONT_NAME' installed."
}

installStarshipAndFzf() {
	log_info "Entering installStarshipAndFzf"

	if command_exists starship; then
		log_info "Starship already installed."
	else
		log_info "Installing Starship prompt..."

		if curl -fsSL https://starship.rs/install.sh | sh -s -- -y; then
			log_info "Starship installer finished."
		else
			die "Starship installer failed."
		fi

		export PATH="$HOME/.local/bin:$PATH"

		if command_exists starship; then
			log_info "Starship installed successfully: $(command -v starship)"
		elif [[ -x "$HOME/.local/bin/starship" ]]; then
			log_warn "Starship installed at $HOME/.local/bin/starship, but ~/.local/bin is not in PATH."
		else
			die "Starship installation completed, but the binary was not found."
		fi
	fi

	if command_exists fzf; then
		log_info "fzf already installed."
	else
		log_info "Installing fzf..."

		if git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"; then
			if [[ -f "$HOME/.fzf/install" ]]; then
				"$HOME/.fzf/install" --all || die "fzf installer failed."
			else
				die "fzf install script not found."
			fi
		else
			die "Failed to clone fzf repository."
		fi
	fi
}

installStarshipConfig() {
	local raw_url="https://raw.githubusercontent.com/csouzape/bashconfig/main/starship.toml"
	local dest="$HOME/.config/starship.toml"

	read -rp "Would you like to install the starship config from csouzape/bashconfig? [y/N]: " ans < /dev/tty
	if [[ "${ans,,}" != "y" && "${ans,,}" != "yes" ]]; then
		log_info "Skipping starship config installation."
		return
	fi

	mkdir -p "$(dirname "$dest")"
	if [ -f "$dest" ]; then
		cp -v "$dest" "$dest.bak" || log_warn "Failed to backup existing starship.toml"
	fi

	if curl -fsSL "$raw_url" -o "$dest"; then
		log_info "starship.toml installed to $dest"
		return 0
	fi

	# Fallback: if repo was cloned, try to copy from it
	if [ -f "$gitpath/starship.toml" ]; then
		cp -v "$gitpath/starship.toml" "$dest" || { log_warn "Failed to copy starship.toml from cloned repo."; return 1; }
		log_info "starship.toml copied from cloned repo to $dest"
		return 0
	fi

	log_warn "Failed to obtain starship.toml from remote or cloned repo."
	return 1
}

installZoxide() {
	if command_exists zoxide; then
		log_info "zoxide already installed."
		return
	fi
	log_info "Installing zoxide..."
	curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash || log_warn "zoxide install script failed."
}

linkConfig() {
	OLD_BASHRC="$HOME/.bashrc"
	if [ -e "$OLD_BASHRC" ] && [ ! -e "$HOME/.bashrc.bak" ]; then
		log_warn "Moving old bash config to $HOME/.bashrc.bak"
		mv "$OLD_BASHRC" "$HOME/.bashrc.bak" || die "Can't move old bash config file."
	fi

	log_info "Linking new bash config..."
	mkdir -p "$HOME/.config"
	if [ -f "$gitpath/.bashrc" ]; then
		ln -svf "$gitpath/.bashrc" "$HOME/.bashrc" || die "Failed to create symbolic link for .bashrc"
	else
		log_warn "No .bashrc in $gitpath; skipping .bashrc link."
	fi

	if [ -f "$gitpath/starship.toml" ]; then
		ln -svf "$gitpath/starship.toml" "$HOME/.config/starship.toml" || die "Failed to create symbolic link for starship.toml"
	else
		log_warn "No starship.toml in $gitpath; skipping starship link."
	fi
	log_info "Done! Restart your shell to see the changes."
}

main() {
	installDepend
	cloneMyBash
	installFont
	installStarshipAndFzf
	installStarshipConfig
	installZoxide
	linkConfig
}
if ! (return 0 2>/dev/null); then
	main "$@"
fi
