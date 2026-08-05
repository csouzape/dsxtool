 

<h1 align="center">dsxtool</h1>

<p align="center">
  <strong>A modular, interactive Linux setup tool — powered by <code>fzf</code>.</strong>
</p>

<p align="center">
  <img width="1621" height="916" alt="image" src="https://github.com/user-attachments/assets/ad0ec258-ea9e-4283-8c2c-2a0a69cd7897" />

</p>

<p align="center">
  <img src="https://img.shields.io/badge/bash-4.0+-4EAA25?style=flat&logo=gnubash&logoColor=white" />
  <img src="https://img.shields.io/badge/license-GPLv2-brightgreen?style=flat&logo=gnu" />
  <a href="https://dsxtool.vercel.app"><img src="https://img.shields.io/badge/part%20of-DSX%20ecosystem-cba6f7?style=flat" /></a>
</p>

---

## Part of the DSX Ecosystem

**dsxtool** is part of the **DSX** (*Direct System eXtensions*) ecosystem — a collection of fast, efficient tools built for Linux power users.

| Tool | Description |
|------|-------------|
| [dsxtool](https://github.com/csouzape/dsxtool) | Post-install automation with interactive fzf TUI |
| [dsxswap](https://github.com/csouzape/dsxtool/blob/testing/modules/dsxswap.sh) | Configure your swapfile and swaptype |
| [dsxsecurity](https://github.com/csouzape/blob/testing/modules/dsxsecurity.sh) | Configure security settings |

---

## Overview

**dsxtool** is a Bash-based toolbox for automating common Linux post-install tasks. It detects your distribution automatically and provides an interactive `fzf` menu to install and configure tools[...]

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

- or for arch linux users 
```
yay -S dsxtool  #or git for you preference
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
| **Setup Bluetooth** | Installs and configures Bluetooth |
| **Setup Printer** | Installs CUPS and printer drivers |
| **DSXSWAP (BETA)** | Configure swap files and swap settings |
| **Setup Fastfetch** | Installs and configures Fastfetch |
| **Setup Bash** | Installs Bash script utilities and shell setup helpers |
| **System Maintenance** | Cleans cache, removes orphan packages, trims disks, and prunes package manager data |
| **Setup yay** *(Arch only)* | Installs the yay AUR helper |
| **Setup paru** *(Arch only)* | Installs the paru AUR helper |

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
    ├── bash.sh
    ├── change_desktop.sh
    ├── development_setup.sh
    ├── dsxswap.sh
    ├── fastfetch.sh
    ├── flatpak.sh
    ├── fonts.sh
    ├── install_apps.sh
    ├── maintenance.sh
    ├── nvidia.sh
    ├── setup_bluetooth.sh
    ├── setup_gaming.sh
    ├── setup_printer.sh
    ├── setup_virtualization.sh
    ├── setupyay.sh
    ├── setupparu.sh
    ├── shell_personalization.sh
    ├── sober_optimization.sh
    ├── tlp.sh
    └── update_system.sh
```

---

## How It Works

On launch, `install.sh` sources `core/common.sh` and `core/detect.sh`, which sets the `$DISTRO` variable to `arch`, `debian`, or `fedora`. The corresponding distro file under `core/distros/` is t[...]

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
- New features must expose **a single entry-point function`
- All package operations must use the **distro abstraction layer** (`pkg_install`, `pkg_remove`, `pkg_exists`)
- Avoid hardcoding distro-specific logic inside modules

---

## License

This project is licensed under the GNU General Public License v2.0.
See the LICENSE file for details.
