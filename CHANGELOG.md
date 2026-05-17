# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.4.1] - 2026-05-17

### Changed
- **Terminal management consolidated**: Integrated Alacritty, Kitty, Konsole, and Ghostty installers into the `Install Apps` menu under a new "Terminals" category, reducing complexity and improving organization
- **Removed standalone terminal modules**: Eliminated separate module files for Alacritty, Kitty, Konsole, and Ghostty, streamlining the codebase
- **Removed wallpapers module**: Deleted the `wallpapers.sh` module and its standalone menu entry, reducing clutter

### Added
- **Terminals category in Install Apps**: New submenu allowing users to install Alacritty, Kitty, Konsole, or Ghostty through a unified interface
- **Terminal-specific installation logic**: Added `_install_terminal_app()` function to handle distribution-specific terminal installation procedures, especially Ghostty's complex COPR setup on Fedora
- **Alacritty configuration prompt**: Integrated csouzape's Alacritty configuration into the terminal installer workflow

### Improved
- **Menu simplification**: Reduced main menu options from 20 (or 21 with yay on Arch) to 15 (or 16 with yay on Arch), improving UX and navigation
- **Codebase maintainability**: Centralized app installation logic in `install_apps.sh` using an `APP_REGISTRY` system, making future additions easier
- **Project structure**: Cleaner module organization focusing on core functionality rather than individual tool installers

### Technical Details
- Implemented `terminal` method type in `APP_REGISTRY` for terminal-specific installation handling
- Updated `_is_installed()`, `_remove_app()`, and `_install_app()` functions to support the new terminal method
- Added special case handling for Ghostty's COPR installation on Fedora within `_install_terminal_app()`

---

## [1.4.0] - Stable

### Previous Release
Baseline stable version with individual terminal modules and standalone wallpapers setup option.

---
