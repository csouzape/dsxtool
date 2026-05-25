

<h1 align="center">dsxtool</h1>

<p align="center">
  <strong>A modular, interactive Linux setup tool — powered by <code>fzf</code>.</strong>
</p>

<p align="center">
  <img width="1428" height="745" alt="image" src="https://github.com/user-attachments/assets/4e2858b4-da25-4a9c-a8c5-748a5bb89657" />
</p>

<p align="center">
  <img src="https://img.shields.io/badge/bash-4.0+-4EAA25?style=flat&logo=gnubash&logoColor=white" />
  <img src="https://img.shields.io/github/license/csouzape/dsxtool" />
  <a href="https://dsxtool.vercel.app"><img src="https://img.shields.io/badge/part%20of-DSX%20ecosystem-cba6f7?style=flat" /></a>
</p>

---

## Part of the DSX Ecosystem

**dsxtool** is part of the **DSX** (*Direct System eXtensions*) ecosystem — a collection of fast, efficient tools built for Linux power users.

| Tool | Description |
|------|-------------|
| [dsxtool](https://github.com/csouzape/dsxtool) | Post-install automation with interactive fzf TUI |
| [dsxconfig](https://github.com/csouzape/dsxconfig) | Backup and restore packages across machines |
| [dsxswap | Configure your swapfile and swaptype |

---

## Overview

**dsxtool** is a Bash-based toolbox for automating common Linux post-install tasks. It detects your distribution automatically and provides an interactive `fzf` menu to install and configure tools, desktop environments, power management, virtualization, fonts, and more.

Supports **Arch Linux**, **Debian/Ubuntu**, and **Fedora**.

---

## Requirements

- `bash` 4.0+
- `fzf` (the script will offer to install it automatically if missing)
- `git`
- `sudo` privileges

---

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/csouzape/dsxtool/main/bootstrap.sh | bash
```

---

## Features

| Option | Description |
|--------|-------------|
| **Update System** | Runs a full system upgrade using the distro's package manager |
| **Install TLP** | Detects the current power manager and offers to replace it with TLP |
| **Install Apps** | Categorized app installer: Browsers, Media, Communication, Productivity, Gaming, System Tools, Terminals, Development |
| **Change Desktop Environment** | Installs KDE Plasma, XFCE, Hyprland, Cosmic, or Hyprland csouzape edition |
| **Fonts Downloader** | Downloads and installs Nerd Fonts and developer fonts |
| **Setup Flatpak** | Installs Flatpak and adds the Flathub remote |
| **Setup Virtualization** | KVM/QEMU with virt-manager or VirtualBox |
| **Setup Shell** | Installs and configures Zsh or Fish with plugins |
| **Setup Gaming** | Wine, Steam, Lutris, MangoHud, GameMode and gaming libraries |
| **DSXConfig** | Launch [dsxconfig](https://github.com/csouzape/dsxconfig) to backup or restore your packages |
| **Setup yay** *(Arch only)* | Installs the yay AUR helper |

---

## Project Structure

```
dsxtool/
├── bootstrap.sh
├── contributing.md
├── install.sh
├── CHANGELOG.md
├── LICENSE
├── README.md
├── core/
│   ├── common.sh
│   ├── detect.sh
│   ├── preview.sh
│   └── distros/
│       ├── arch.sh
│       ├── debian.sh
│       └── fedora.sh
└── modules/
    ├── change_desktop.sh
    ├── development_setup.sh
    ├── dsxconfig.sh
    ├── dsxswap.sh
    ├── flatpak.sh
    ├── fonts.sh
    ├── install_apps.sh
    ├── setup_bluetooth.sh
    ├── setup_gaming.sh
    ├── setup_printer.sh
    ├── setup_virtualization.sh
    ├── setupyay.sh
    ├── shell_personalization.sh
    ├── tlp.sh
    └── update_system.sh
```

---

## How It Works

On launch, `install.sh` sources `core/common.sh` and `core/detect.sh`, which sets the `$DISTRO` variable to `arch`, `debian`, or `fedora`. The corresponding distro file under `core/distros/` is then sourced, providing unified `pkg_install`, `pkg_remove`, and `pkg_exists` functions used across all modules.

Each menu option sources its module on demand and calls a single entry-point function — keeping the codebase modular and easy to extend.

---

## Contributing

Contributions are welcome.

If you want to contribute to **dsxtool**, please read the contribution guidelines first:

**[Contribution Guide](contributing.md)**

### Reporting Issues

Before opening a new issue, check if it already exists. Use the provided templates:

- **Bug reports:** `.github/bug_report.md`
- **Feature requests:** `.github/feature_request.md`

### Development Notes

- Modules should remain **self-contained Bash scripts** inside `modules/`
- New features must expose **a single entry-point function**
- All package operations must use the **distro abstraction layer** (`pkg_install`, `pkg_remove`, `pkg_exists`)
- Avoid hardcoding distro-specific logic inside modules

---

## License

[MIT](LICENSE)
